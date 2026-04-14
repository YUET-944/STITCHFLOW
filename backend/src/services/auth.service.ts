import { PrismaClient } from "@prisma/client";
import { FastifyInstance } from "fastify";
import { SequenceService } from "./sequence.service";
import * as bcrypt from "bcrypt";

export class AuthService {
  private sequenceService: SequenceService;

  constructor(private prisma: PrismaClient, private fastify: FastifyInstance) {
    this.sequenceService = new SequenceService(prisma);
  }

  async register(body: any) {
    const { role, full_name, username, password, email, city, business_name, specializations, price_min, price_max } = body;

    const existingUser = await this.prisma.user.findUnique({
      where: { username }
    });
    if (existingUser) throw new Error("USERNAME_ALREADY_EXISTS");

    const readable_id = await this.sequenceService.generateReadableId(role, city || "Unknown");

    const saltRounds = 12;
    const password_hash = await bcrypt.hash(password, saltRounds);

    const user = await this.prisma.$transaction(async (tx) => {
      const u = await tx.user.create({
        data: {
          readable_id,
          role,
          full_name,
          username,
          password_hash,
          email: email || null,
          location_city: city,
          account_status: "ACTIVE",
        }
      });

      if (role === "TAILOR") {
        await tx.tailorProfile.create({
          data: {
            tailor_id: u.id,
            business_name: business_name || full_name,
            specializations: specializations || [],
            price_per_suit_min: price_min || null,
            price_per_suit_max: price_max || null,
          }
        });
      }

      return tx.user.findUnique({ where: { id: u.id }, include: { tailor_profile: true } });
    });

    const accessToken = (this.fastify as any).jwt.sign(
      { sub: user!.id, role: user!.role, readable_id: user!.readable_id },
      { expiresIn: "60m" }
    );
    const refreshToken = (this.fastify as any).jwt.sign(
      { sub: user!.id, type: "refresh" },
      { expiresIn: "30d" }
    );

    return { 
      accessToken, 
      refreshToken, 
      user: { 
        id: user!.id, 
        readable_id: user!.readable_id, 
        role: user!.role, 
        full_name: user!.full_name, 
        username: user!.username,
        city: user!.location_city
      } 
    };
  }

  async login(body: any) {
    const { username, password } = body;

    const user = await this.prisma.user.findUnique({
      where: { username },
      include: { tailor_profile: true }
    });

    if (!user) {
      throw new Error("INVALID_CREDENTIALS");
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      throw new Error("INVALID_CREDENTIALS");
    }

    const accessToken = (this.fastify as any).jwt.sign(
      { sub: user.id, role: user.role, readable_id: user.readable_id },
      { expiresIn: "60m" }
    );
    const refreshToken = (this.fastify as any).jwt.sign(
      { sub: user.id, type: "refresh" },
      { expiresIn: "30d" }
    );

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        readable_id: user.readable_id,
        role: user.role,
        full_name: user.full_name,
        username: user.username,
        city: user.location_city,
        tailor_profile: user.tailor_profile
      }
    };
  }

  async refreshToken(token: string) {
    try {
      const payload: any = (this.fastify as any).jwt.verify(token);
      if (payload.type !== "refresh") throw new Error("INVALID_TOKEN");

      const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
      if (!user) throw new Error("INVALID_CREDENTIALS");

      const accessToken = (this.fastify as any).jwt.sign(
        { sub: user.id, role: user.role, readable_id: user.readable_id },
        { expiresIn: "60m" }
      );
      return { accessToken };
    } catch {
      throw new Error("INVALID_OR_EXPIRED_REFRESH_TOKEN");
    }
  }
}
