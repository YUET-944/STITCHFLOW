import { PrismaClient } from "@prisma/client";

export class SearchService {
  constructor(private prisma: PrismaClient) {}

  /** Anonymous track by Order ID or Client Readable ID — no auth required */
  async trackByReadableId(readableId: string) {
    let order: any = null;
    let client: any = null;

    // 1. Try treating as direct Order ID first (starts with SF-O)
    if (readableId.startsWith("SF-O-")) {
      order = await this.prisma.order.findUnique({
        where: { id: readableId },
        include: {
          garments: {
            select: {
              garment_type: true,
              delivery_stage: true,
              stage_history: true,
              requirements: true,
            }
          },
          tailor: { select: { full_name: true } },
          client: { select: { full_name: true, readable_id: true } },
          invoice: true
        }
      });
      if (order) client = order.client;
    } 
    
    // 2. If not found, try treating as Client Readable ID
    if (!order) {
      client = await this.prisma.user.findUnique({
        where: { readable_id: readableId },
        select: { id: true, full_name: true, role: true, readable_id: true }
      });

      if (client && client.role === "CLIENT") {
        order = await this.prisma.order.findFirst({
          where: {
            client_id: client.id,
            booking_status: { in: ["CONFIRMED", "PENDING", "COMPLETED"] }
          },
          orderBy: { created_at: "desc" },
          include: {
            garments: {
              select: {
                garment_type: true,
                delivery_stage: true,
                stage_history: true,
                requirements: true,
              }
            },
            tailor: { select: { full_name: true } },
            invoice: true
          }
        });
      }
    }

    if (!order && !client) throw new Error("TRACKING_ID_NOT_FOUND");

    return {
      client_first_name: client?.full_name?.split(" ")[0] || "Client",
      readable_id: readableId,
      has_active_order: !!order,
      order: order ? {
        id: order.id,
        status: order.booking_status,
        garments: order.garments,
        preferred_date_end: order.preferred_date_end,
        tailor_name: order.tailor?.full_name,
        invoice: order.invoice ? {
          payment_status: order.invoice.payment_status,
          balance_due: order.invoice.balance_due,
        } : null,
        chat_channel_id: order.chat_channel_id,
      } : null,
    };
  }

  /** Geo-search tailors by city, specialization, availability */
  async searchTailors(params: {
    city?: string;
    specialization?: string;
    availability?: string;
    price_min?: number;
    price_max?: number;
    limit?: number;
  }) {
    const { city, specialization, availability, price_min, price_max, limit = 20 } = params;

    const tailors = await this.prisma.user.findMany({
      where: {
        role: "TAILOR",
        is_verified: true,
        account_status: "ACTIVE",
        ...(city ? { location_city: { contains: city, mode: "insensitive" } } : {}),
        tailor_profile: {
          ...(availability ? { availability_status: availability as any } : {}),
          ...(specialization ? { specializations: { has: specialization } } : {}),
          ...(price_min ? { price_per_suit_min: { gte: price_min } } : {}),
          ...(price_max ? { price_per_suit_max: { lte: price_max } } : {}),
        }
      },
      include: {
        tailor_profile: {
          select: {
            business_name: true,
            specializations: true,
            availability_status: true,
            max_active_orders: true,
            current_active_orders: true,
            price_per_suit_min: true,
            price_per_suit_max: true,
            portfolio_urls: true,
            portfolio_cover_idx: true,
            total_completed_orders: true,
          }
        }
      },
      take: limit,
    });

    return tailors.map(t => ({
      id: t.id,
      readable_id: t.readable_id,
      full_name: t.full_name,
      location_address: t.location_address,
      city: t.location_city,
      profile_photo_url: t.profile_photo_url,
      tailor_profile: t.tailor_profile,
    }));
  }

  /** Public tailor profile by ID */
  async getTailorPublicProfile(tailorId: string) {
    const tailor = await this.prisma.user.findUnique({
      where: { id: tailorId },
      include: { tailor_profile: true }
    });
    if (!tailor || tailor.role !== "TAILOR") throw new Error("TAILOR_NOT_FOUND");

    return {
      id: tailor.id,
      readable_id: tailor.readable_id,
      full_name: tailor.full_name,
      location_address: tailor.location_address,
      city: tailor.location_city,
      profile_photo_url: tailor.profile_photo_url,
      is_verified: tailor.is_verified,
      tailor_profile: tailor.tailor_profile,
    };
  }
}
