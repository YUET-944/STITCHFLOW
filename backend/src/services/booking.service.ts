import { PrismaClient, Prisma } from "@prisma/client";
import { randomUUID } from "crypto";

export class BookingService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Capacity Gate: Serialized Transaction (Race-Condition Proof)
   * Acquires row-level lock on tailor_profiles before checking capacity.
   */
  async createBooking(tailorId: string, clientId: string, bookingPayload: any) {
    const VALID_GARMENTS = ["SUIT", "SHIRT", "TROUSER", "KAMEEZ", "SHALWAR", "WAISTCOAT", "SHERWANI"];
    
    return await this.prisma.$transaction(async (tx) => {
      // 1. Acquire row-level lock on tailor profile
      const tailor: any[] = await tx.$queryRaw`
        SELECT current_active_orders, max_active_orders, availability_status
        FROM tailor_profiles
        WHERE tailor_id = ${tailorId}::uuid
        FOR UPDATE
      `;

      if (!tailor.length) throw new Error("TAILOR_NOT_FOUND");
      const t = tailor[0];

      // 2. Capacity enforcement
      if (t.current_active_orders >= t.max_active_orders) {
        throw new Error("CAPACITY_EXCEEDED");
      }

      // 3. Availability check
      if (t.availability_status !== "ACTIVE") {
        throw new Error("TAILOR_UNAVAILABLE");
      }

      // 4. Create Order
      const orderId = `SF-O-${tailorId.substring(0,4).toUpperCase()}-${clientId.substring(0,4).toUpperCase()}-${Date.now()}`;
      
      const order = await tx.order.create({
        data: {
          id: orderId,
          tailor_id: tailorId,
          client_id: clientId,
          preferred_date_start: new Date(bookingPayload.preferredDateStart),
          preferred_date_end: new Date(bookingPayload.preferredDateEnd),
          special_instructions: bookingPayload.specialInstructions
        }
      });

      // 5. Create garments with validation
      if (bookingPayload.garments && bookingPayload.garments.length > 0) {
        for (const gType of bookingPayload.garments) {
          if (!VALID_GARMENTS.includes(gType.toUpperCase())) {
            throw new Error(`INVALID_GARMENT_TYPE: ${gType}`);
          }
          await tx.orderGarment.create({
            data: {
              order_id: order.id,
              garment_type: gType.toUpperCase()
            }
          });
        }
      }

      return order;
    }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
  }
}
