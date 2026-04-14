import { PrismaClient } from "@prisma/client";

export class POSService {
  constructor(private prisma: PrismaClient) {}

  async executePOSAction(tailorId: string, orderId: string, posPayload: any) {
    // 1. Unified Transaction to generate Invoice, update Order, and persist PDF stubs
    return await this.prisma.$transaction(async (tx) => {
      const order = await tx.order.findUnique({ where: { id: orderId } });
      if (!order || order.tailor_id !== tailorId) throw new Error("ORDER_NOT_FOUND");
      if (order.booking_status !== "CONFIRMED") throw new Error("INVALID_STATE");

      // Generate invoice ID
      const tailorShort = tailorId.substring(0,4).toUpperCase();
      const invoiceId = `SF-INV-${tailorShort}-${new Date().getFullYear().toString().substring(2)}-${Date.now()}`;

      const advance = posPayload.advancePaid || 0;
      const base = posPayload.basePrice || 0;
      const balance = base - advance;
      const status = advance >= base ? "FULLY_PAID" : (advance > 0 ? "ADVANCE_RECEIVED" : "BALANCE_PENDING");

      const invoice = await tx.invoice.create({
        data: {
          id: invoiceId,
          order_id: orderId,
          tailor_id: tailorId,
          client_id: order.client_id,
          base_price: base,
          advance_paid: advance,
          balance_due: balance,
          payment_status: status,
          pdf_url: `mock_cloudinary_url_invoice_${invoiceId}.pdf`
        }
      });

      const updatedOrder = await tx.order.update({
        where: { id: orderId },
        data: { 
          invoice_id: invoiceId, 
          stitching_ticket_id: `mock_cloudinary_url_ticket_${orderId}.pdf`
        }
      });

      return { invoice, order: updatedOrder, invoicePdfUrl: invoice.pdf_url };
    });
  }

  async advanceGarmentStage(tailorId: string, garmentId: string, newStage: string) {
    const garment = await this.prisma.orderGarment.findUnique({
      where: { id: garmentId },
      include: { order: true }
    });

    if (!garment || garment.order.tailor_id !== tailorId) throw new Error("GARMENT_NOT_FOUND");

    const historyEntry = { stage: newStage, advanced_at: new Date(), advanced_by: tailorId };
    const currentHistory = (garment.stage_history as any[]) || [];

    const updated = await this.prisma.orderGarment.update({
      where: { id: garmentId },
      data: {
        delivery_stage: newStage as any, // Cast to enum
        stage_history: [...currentHistory, historyEntry] as any // Append only payload
      }
    });

    // Event emission (e.g. Socket.io) would go here
    return updated;
  }
}
