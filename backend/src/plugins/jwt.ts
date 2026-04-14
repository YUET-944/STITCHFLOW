import fp from "fastify-plugin";
import fastifyJwt from "@fastify/jwt";
import { FastifyReply, FastifyRequest } from "fastify";
import { Role } from "@prisma/client";

declare module "fastify" {
  interface FastifyInstance {
    authenticate: (request: FastifyRequest, reply: FastifyReply) => Promise<void>;
    requireRole: (roles: Role[]) => (request: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
}

declare module "@fastify/jwt" {
  interface FastifyJWT {
    payload: { sub: string; role: Role }; 
    user: { sub: string; role: Role }; 
  }
}

export default fp(async (fastify, opts) => {
  const secret = process.env.JWT_ACCESS_SECRET;

  if (!secret) {
    throw new Error("FATAL: JWT_ACCESS_SECRET environment variable must be strictly defined in all environments.");
  }

  fastify.register(fastifyJwt, {
    secret: secret,
  });

  fastify.decorate("authenticate", async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      await request.jwtVerify();
    } catch (err) {
      return reply.code(401).send({ error: "INVALID_OR_EXPIRED_TOKEN" });
    }
  });

  fastify.decorate("requireRole", (roles: Role[]) => async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      await request.jwtVerify();
    } catch (err) {
      return reply.code(401).send({ error: "INVALID_OR_EXPIRED_TOKEN" });
    }

    if (!roles.includes(request.user.role)) {
      return reply.code(403).send({ error: "ROLE_FORBIDDEN" });
    }
  });
});
