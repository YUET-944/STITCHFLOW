import { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Role } from "@prisma/client";
import { MeasurementService } from "../services/measurement.service";
import { MeasurementDTO } from "../schemas/measurement.schema";
import { prisma } from "../lib/prisma";

const measurementRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  const measurementService = new MeasurementService(prisma);

  // POST /measurements (Only TAILOR role permitted - GATE 1)
  fastify.post(
    "/",
    {
      preHandler: fastify.requireRole([Role.TAILOR]),
      schema: { body: MeasurementDTO }
    },
    async (request, reply) => {
      try {
        const tailorId = request.user.sub;
        const result = await measurementService.saveMeasurement(tailorId, request.body.clientId, request.body);
        return reply.code(201).send(result);
      } catch (error: any) {
        if (error.message === "LINK_NOT_FOUND") {
          return reply.code(403).send({ error: "No active order link between tailor and client" });
        }
        return reply.code(500).send({ error: error.message });
      }
    }
  );

  // GET /measurements/vault/:clientId
  fastify.get(
    "/vault/:clientId",
    { preHandler: fastify.authenticate },
    async (request, reply) => {
      try {
        const { clientId } = request.params as { clientId: string };
        const result = await measurementService.getMeasurementHistory(clientId, request.user.sub, request.user.role);
        return result;
      } catch (error: any) {
        return reply.code(403).send({ error: error.message });
      }
    }
  );
};

export default measurementRoutes;
