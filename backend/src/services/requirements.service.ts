import { PrismaClient } from "@prisma/client";

const GARMENT_REQUIREMENTS: Record<string, Record<string, string[]>> = {
  default: {
    neck_type: ["Mandarin", "Spread", "Point", "Band", "Button-Down"],
    pocket_style: ["Flap", "Patch", "Jetted", "None"],
    sleeve_treatment: ["Full", "Half", "Three-Quarter", "Rolled"],
    lining_colour: ["White", "Black", "Navy", "Ivory", "Custom"],
    button_colour: ["Gold", "Silver", "Black", "Pearl", "Matching Fabric"],
  }
};

export class RequirementsService {
  constructor(private prisma: PrismaClient) {}

  /** GET requirements checklist for an order (per garment) */
  async getRequirements(orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { garments: { select: { id: true, garment_type: true, requirements: true } } }
    });
    if (!order) throw new Error("ORDER_NOT_FOUND");

    return order.garments.map(g => ({
      garment_id: g.id,
      garment_type: g.garment_type,
      options: GARMENT_REQUIREMENTS["default"],
      current_requirements: g.requirements,
      is_verified: order.requirements_verified,
    }));
  }

  /** POST: Client verifies requirements — freezes checklist and unlocks IN_PRODUCTION */
  async verifyRequirements(orderId: string, clientId: string, requirementsByGarment: Record<string, any>) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { garments: true }
    });
    if (!order) throw new Error("ORDER_NOT_FOUND");
    if (order.client_id !== clientId) throw new Error("FORBIDDEN");
    if (order.requirements_verified) throw new Error("ALREADY_VERIFIED");

    return this.prisma.$transaction(async (tx) => {
      // Freeze requirements on each garment
      for (const garment of order.garments) {
        const reqs = requirementsByGarment[garment.id] || {};
        await tx.orderGarment.update({
          where: { id: garment.id },
          data: { requirements: reqs }
        });
      }

      // Mark order as verified
      return tx.order.update({
        where: { id: orderId },
        data: {
          requirements_verified: true,
          requirements_verified_at: new Date(),
        }
      });
    });
  }

  /** Auto-approve with defaults after 24h (call from a cron job placeholder) */
  async autoApproveExpired() {
    const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const pendingVerification = await this.prisma.order.findMany({
      where: {
        booking_status: "CONFIRMED",
        requirements_verified: false,
        confirmed_at: { lte: cutoff }
      },
      include: { garments: true }
    });

    for (const order of pendingVerification) {
      const defaults: Record<string, any> = {};
      for (const g of order.garments) {
        defaults[g.id] = {
          neck_type: "Mandarin",
          pocket_style: "Flap",
          sleeve_treatment: "Full",
          lining_colour: "White",
          button_colour: "Gold",
        };
      }
      await this.verifyRequirements(order.id, order.client_id, defaults);
      // Fix #20: Client Notification Trigger
      console.log(`[NOTIFICATION] Order ${order.id} requirements auto-verified after 24h.`);
    }

    return pendingVerification.length;
  }
}
