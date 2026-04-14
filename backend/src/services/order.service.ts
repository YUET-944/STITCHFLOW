import { PrismaClient } from "@prisma/client";
import { randomUUID } from "crypto";

const REJECTION_REASONS = [
  "FULLY_BOOKED",
  "SPECIALIZATION_MISMATCH",
  "TIMELINE_UNAVAILABLE",
  "CLIENT_REQUEST_UNCLEAR",
  "OTHER",
] as const;

export class OrderService {
  constructor(private prisma: PrismaClient) {}

  /** GET: Tailor's pending approval queue */
  async getTailorQueue(tailorId: string) {
    return this.prisma.order.findMany({
      where: { tailor_id: tailorId, booking_status: "PENDING" },
      orderBy: { created_at: "asc" },
      include: {
        client: { select: { full_name: true, readable_id: true, profile_photo_url: true } },
        garments: { select: { garment_type: true } },
      }
    });
  }

  /** GET: Tailor's active orders */
  async getTailorActiveOrders(tailorId: string) {
    return this.prisma.order.findMany({
      where: {
        tailor_id: tailorId,
        booking_status: { in: ["CONFIRMED"] }
      },
      orderBy: { confirmed_at: "asc" },
      include: {
        client: { select: { full_name: true, readable_id: true } },
        garments: {
          include: { staff_master: { select: { name: true } } }
        },
        invoice: { select: { payment_status: true, balance_due: true } }
      }
    });
  }

  /** GET: Client's order history */
  async getClientOrders(clientId: string) {
    return this.prisma.order.findMany({
      where: { client_id: clientId },
      orderBy: { created_at: "desc" },
      include: {
        tailor: { select: { full_name: true, readable_id: true } },
        garments: { select: { garment_type: true, delivery_stage: true } },
        invoice: { select: { payment_status: true, balance_due: true } }
      }
    });
  }

  /** GET: Single order detail (role-filtered) */
  async getOrderDetail(orderId: string, userId: string, role: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        tailor: { select: { full_name: true, readable_id: true, username: true, location_address: true } },
        client: { select: { full_name: true, readable_id: true } },
        garments: {
          include: {
            staff_master: { select: { name: true, specialty: true } },
            measurement: true
          }
        },
        invoice: true
      }
    });

    if (!order) throw new Error("ORDER_NOT_FOUND");

    // Access control
    if (role === "CLIENT" && order.client_id !== userId) throw new Error("FORBIDDEN");
    if (role === "TAILOR" && order.tailor_id !== userId) throw new Error("FORBIDDEN");

    // Hide username from client if not confirmed
    if (role === "CLIENT" && order.booking_status !== "CONFIRMED") {
      (order.tailor as any).username = null;
    }

    return order;
  }

  /** PATCH: Approve booking */
  async approveOrder(tailorId: string, orderId: string) {
    return this.prisma.$transaction(async (tx) => {
      const order = await tx.order.findUnique({ where: { id: orderId } });
      if (!order || order.tailor_id !== tailorId) throw new Error("ORDER_NOT_FOUND");
      if (order.booking_status !== "PENDING") throw new Error("ORDER_ALREADY_PROCESSED");

      const updatedOrder = await tx.order.update({
        where: { id: orderId },
        data: {
          booking_status: "CONFIRMED",
          confirmed_at: new Date(),
          chat_channel_id: `chat_${orderId}`,
        }
      });

      const linkId = randomUUID(); // Bug fix: was using substring collision-prone ID
      await tx.$executeRaw`
        INSERT INTO tailor_client_links (id, tailor_id, client_id, is_active, linked_at, order_count)
        VALUES (${linkId}, ${tailorId}::uuid, ${order.client_id}::uuid, true, NOW(), 1)
        ON CONFLICT (tailor_id, client_id) DO UPDATE SET order_count = tailor_client_links.order_count + 1
      `;

      await tx.$executeRaw`
        UPDATE tailor_profiles SET current_active_orders = current_active_orders + 1
        WHERE tailor_id = ${tailorId}::uuid
      `;

      return updatedOrder;
    });
  }

  /** PATCH: Reject booking with reason code */
  async rejectOrder(tailorId: string, orderId: string, reason: string, notes?: string) {
    if (!REJECTION_REASONS.includes(reason as any)) throw new Error("INVALID_REASON_CODE");

    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order || order.tailor_id !== tailorId) throw new Error("ORDER_NOT_FOUND");
    if (order.booking_status !== "PENDING") throw new Error("ORDER_ALREADY_PROCESSED");

    return this.prisma.order.update({
      where: { id: orderId },
      data: {
        booking_status: "REJECTED",
        rejection_reason: reason,
        rejection_notes: notes ?? null,
      }
    });
  }

  /** PATCH: Cancel order (client or tailor, pre-production only) */
  async cancelOrder(userId: string, orderId: string, role: string) {
    return this.prisma.$transaction(async (tx) => {
      const order = await tx.order.findUnique({ where: { id: orderId } });
      if (!order) throw new Error("ORDER_NOT_FOUND");

      if (role === "CLIENT" && order.client_id !== userId) throw new Error("FORBIDDEN");
      if (role === "TAILOR" && order.tailor_id !== userId) throw new Error("FORBIDDEN");
      if (order.booking_status === "COMPLETED") throw new Error("CANNOT_CANCEL_COMPLETED");

      const wasConfirmed = order.booking_status === "CONFIRMED";

      const updated = await tx.order.update({
        where: { id: orderId },
        data: { booking_status: "CANCELLED" }
      });

      // Decrement capacity counter if order was active — Bug fix
      if (wasConfirmed) {
        await tx.$executeRaw`
          UPDATE tailor_profiles
          SET current_active_orders = GREATEST(0, current_active_orders - 1)
          WHERE tailor_id = ${order.tailor_id}::uuid
        `;
      }

      return updated;
    });
  }
}
