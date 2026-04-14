import { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { Type } from "@sinclair/typebox";
import { Role } from "@prisma/client";
import { prisma } from "../lib/prisma";
import { OrderService } from "../services/order.service";
import { BookingService } from "../services/booking.service";
import { RequirementsService } from "../services/requirements.service";
import { POSService } from "../services/pos.service";

const ordersRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  const orderService = new OrderService(prisma);
  const bookingService = new BookingService(prisma);
  const requirementsService = new RequirementsService(prisma);
  const posService = new POSService(prisma);



  // POST /orders — Client creates booking (capacity gate)
  fastify.post("/", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    if (user.role !== "CLIENT") return reply.code(403).send({ error: "CLIENT_ONLY" });
    try {
      return await bookingService.createBooking(
        (request.body as any).tailor_id,
        user.sub,
        request.body
      );
    } catch (e: any) {
      const code = e.message === "CAPACITY_EXCEEDED" ? 409 : 400;
      return reply.code(code).send({ error: e.message });
    }
  });

  // GET /orders/tailor/queue
  fastify.get("/tailor/queue", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    if (user.role !== "TAILOR") return reply.code(403).send({ error: "TAILOR_ONLY" });
    return orderService.getTailorQueue(user.sub);
  });

  // GET /orders/tailor/active
  fastify.get("/tailor/active", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    if (user.role !== "TAILOR") return reply.code(403).send({ error: "TAILOR_ONLY" });
    return orderService.getTailorActiveOrders(user.sub);
  });

  // GET /orders/client/mine
  fastify.get("/client/mine", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    if (user.role !== "CLIENT") return reply.code(403).send({ error: "CLIENT_ONLY" });
    return orderService.getClientOrders(user.sub);
  });

  // GET /orders/:orderId
  fastify.get("/:orderId", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    try {
      return await orderService.getOrderDetail(
        (request.params as any).orderId,
        user.sub,
        user.role
      );
    } catch (e: any) {
      return reply.code(e.message === "FORBIDDEN" ? 403 : 404).send({ error: e.message });
    }
  });

  // PATCH /orders/:orderId/approve
  fastify.patch("/:orderId/approve", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    if (user.role !== "TAILOR") return reply.code(403).send({ error: "TAILOR_ONLY" });
    try {
      return await orderService.approveOrder(user.sub, (request.params as any).orderId);
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
  });

  // PATCH /orders/:orderId/reject
  fastify.patch("/:orderId/reject", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    if (user.role !== "TAILOR") return reply.code(403).send({ error: "TAILOR_ONLY" });
    const { reason, notes } = request.body as any;
    try {
      return await orderService.rejectOrder(user.sub, (request.params as any).orderId, reason, notes);
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
  });

  // PATCH /orders/:orderId/cancel
  fastify.patch("/:orderId/cancel", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    try {
      return await orderService.cancelOrder(user.sub, (request.params as any).orderId, user.role);
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
  });

  // GET /orders/:orderId/requirements
  fastify.get("/:orderId/requirements", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      return await requirementsService.getRequirements((request.params as any).orderId);
    } catch (e: any) {
      return reply.code(404).send({ error: e.message });
    }
  });

  // POST /orders/:orderId/requirements/verify
  fastify.post("/:orderId/requirements/verify", { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = (request as any).user;
    if (user.role !== "CLIENT") return reply.code(403).send({ error: "CLIENT_ONLY" });
    try {
      return await requirementsService.verifyRequirements(
        (request.params as any).orderId,
        user.sub,
        (request.body as any).requirements_by_garment
      );
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
  });

};

export default ordersRoutes;
