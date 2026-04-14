import { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Role } from "@prisma/client";
import { prisma } from "../lib/prisma";
import { POSService } from "../services/pos.service";
import { POSActionDTO, AdvanceStageDTO } from "../schemas/pos.schema";

const posRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  const posService = new POSService(prisma);

  // POST /orders/:orderId/pos (Unified POS Action)
  fastify.post(
    "/orders/:orderId/pos",
    {
      preHandler: fastify.requireRole([Role.TAILOR]),
      schema: { body: POSActionDTO }
    },
    async (request, reply) => {
      try {
        const tailorId = request.user.sub;
        const { orderId } = request.params as { orderId: string };
        const result = await posService.executePOSAction(tailorId, orderId, request.body);
        return reply.code(200).send(result);
      } catch (error: any) {
        return reply.code(400).send({ error: error.message });
      }
    }
  );

  // PATCH /garments/:garmentId/stage (Advance Production Stage)
  fastify.patch(
    "/garments/:garmentId/stage",
    {
      preHandler: fastify.requireRole([Role.TAILOR]),
      schema: { body: AdvanceStageDTO }
    },
    async (request, reply) => {
      try {
        const tailorId = request.user.sub;
        const { garmentId } = request.params as { garmentId: string };
        const result = await posService.advanceGarmentStage(tailorId, garmentId, request.body.newStage);
        return reply.code(200).send(result);
      } catch (error: any) {
        return reply.code(400).send({ error: error.message });
      }
    }
  );
};

export default posRoutes;
