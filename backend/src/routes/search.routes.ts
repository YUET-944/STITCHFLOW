import { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import { prisma } from "../lib/prisma";
import { SearchService } from "../services/search.service";

const searchRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  const searchService = new SearchService(prisma);

  // ─── GET /search/track?id=:readableId — public, no auth ───────────────────
  // Frontend calls: GET /search/track?id=TR-CENTRAL-001 or SF-O-xxxx
  // Added both path-param and query-param variants for compatibility.
  fastify.get("/track", {
    schema: {
      querystring: Type.Object({
        id: Type.String({ minLength: 1 })
      })
    }
  }, async (request, reply) => {
    try {
      return await searchService.trackByReadableId((request.query as any).id);
    } catch (e: any) {
      return reply.code(404).send({ error: e.message });
    }
  });

  // Legacy path-param variant (kept for backwards compat)
  fastify.get("/track/:readableId", {
    schema: { params: Type.Object({ readableId: Type.String() }) }
  }, async (request, reply) => {
    try {
      return await searchService.trackByReadableId((request.params as any).readableId);
    } catch (e: any) {
      return reply.code(404).send({ error: e.message });
    }
  });

  // ─── GET /search/tailors — JWT optional ───────────────────────────────────
  fastify.get("/tailors", {
    schema: {
      querystring: Type.Object({
        city:           Type.Optional(Type.String()),
        specialization: Type.Optional(Type.String()),
        availability:   Type.Optional(Type.String()),
        price_min:      Type.Optional(Type.Number()),
        price_max:      Type.Optional(Type.Number()),
        limit:          Type.Optional(Type.Number({ minimum: 1, maximum: 100 })),
      })
    }
  }, async (request, reply) => {
    return searchService.searchTailors(request.query as any);
  });
};

export default searchRoutes;
