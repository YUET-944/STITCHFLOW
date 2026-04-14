import { PrismaClient, Role } from "@prisma/client";
import * as bcrypt from "bcrypt";

export class UserRepository {
  constructor(private prisma: PrismaClient) {}

  async findByUsername(username: string) {
    return this.prisma.user.findFirst({
      where: { username } as any,
      include: { tailor_profile: true } as any
    });
  }

  async createUser(data: {
    role: Role;
    full_name: string;
    username: string;
    password_clear: string;
    email?: string;
    city?: string;
    readable_id: string;
    business_name?: string;
    specializations?: string[];
    price_min?: number;
    price_max?: number;
  }) {
    // Generate salt & hash password securely using bcrypt
    const saltRounds = 12;
    const password_hash = await bcrypt.hash(data.password_clear, saltRounds);

    return this.prisma.$transaction(async (tx) => {
      const user = await (tx as any).user.create({
        data: {
          readable_id: data.readable_id,
          role: data.role,
          full_name: data.full_name,
          username: data.username,
          password_hash,
          email: data.email || `${data.username}@stitchflow.local`,
          location_city: data.city,
          account_status: "ACTIVE",
        }
      });

      if (data.role === "TAILOR") {
        await tx.tailorProfile.create({
          data: {
            tailor_id: user.id,
            business_name: data.business_name || data.full_name,
            specializations: data.specializations || [],
            price_per_suit_min: data.price_min || null,
            price_per_suit_max: data.price_max || null,
          }
        });
      }

      return tx.user.findUnique({
        where: { id: user.id },
        include: { tailor_profile: true } as any
      });
    });
  }
}
