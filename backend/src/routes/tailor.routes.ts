import { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import { Role } from "@prisma/client";
import { prisma } from "../lib/prisma";
import { StaffService } from "../services/staff.service";
import { SearchService } from "../services/search.service";

const tailorRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  const staffService = new StaffService(prisma);
  const searchService = new SearchService(prisma);



  // ─── Staff ────────────────────────────────────────────────────────────────
  fastify.post("/staff", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    if (user.role !== "TAILOR") return reply.code(403).send({ error: "TAILOR_ONLY" });
    return staffService.addStaff(user.sub, request.body as any);
  });

  fastify.get("/staff", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    if (user.role !== "TAILOR") return reply.code(403).send({ error: "TAILOR_ONLY" });
    return staffService.listStaff(user.sub);
  });

  fastify.patch("/garments/:garmentId/assign", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    if (user.role !== "TAILOR") return reply.code(403).send({ error: "TAILOR_ONLY" });
    try {
      return await staffService.assignStaff(
        user.sub,
        (request.params as any).garmentId,
        (request.body as any).staff_id
      );
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
  });

  fastify.patch("/staff/:staffId/toggle", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    if (user.role !== "TAILOR") return reply.code(403).send({ error: "TAILOR_ONLY" });
    return staffService.toggleStaff(user.sub, (request.params as any).staffId, (request.body as any).is_active);
  });

  // ─── Garment Stage Advancement → handled by pos.routes.ts ───────────────

  // ─── Public Tailor Profile ───────────────────────────────────────────────
  // Full path: GET /api/v1/tailors/:tailorId
  fastify.get("/:tailorId", async (request, reply) => {
    try {
      return await searchService.getTailorPublicProfile((request.params as any).tailorId);
    } catch (e: any) {
      return reply.code(404).send({ error: e.message });
    }
  });

  // ─── Portfolio Management ────────────────────────────────────────────────
  fastify.patch("/tailor/portfolio", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    if (user.role !== "TAILOR") return reply.code(403).send({ error: "TAILOR_ONLY" });
    const { portfolio_urls, portfolio_cover_idx } = request.body as any;
    return prisma.tailorProfile.update({
      where: { tailor_id: user.sub },
      data: { portfolio_urls, portfolio_cover_idx }
    });
  });

  // ─── POS → handled by pos.routes.ts ─────────────────────────────────────

  // ─── Tailor Profile Update ───────────────────────────────────────────────
  fastify.patch("/tailor/profile", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    if (user.role !== "TAILOR") return reply.code(403).send({ error: "TAILOR_ONLY" });
    const { business_name, specializations, max_active_orders, price_per_suit_min, price_per_suit_max, availability_status } = request.body as any;
    return prisma.tailorProfile.update({
      where: { tailor_id: user.sub },
      data: { business_name, specializations, max_active_orders, price_per_suit_min, price_per_suit_max, availability_status }
    });
  });

  // ─── Measurements ────────────────────────────────────────────────────────
  fastify.get("/client/:clientId/measurements", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    const clientId = (request.params as any).clientId;
    // Role guard
    if (user.role === "CLIENT" && user.sub !== clientId) return reply.code(403).send({ error: "FORBIDDEN" });
    return prisma.measurement.findMany({
      where: { client_id: clientId },
      orderBy: { recorded_at: "desc" },
      include: { tailor: { select: { full_name: true, readable_id: true } } }
    });
  });
};

export default tailorRoutes;
