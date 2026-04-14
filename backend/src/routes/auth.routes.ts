import { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import { RegisterDTO, LoginDTO } from "../schemas/auth.schema";
import { AuthService } from "../services/auth.service";
import { Type } from "@sinclair/typebox";
import { prisma } from "../lib/prisma";

const authRoutes: FastifyPluginAsyncTypebox = async (fastify) => {
  const authService = new AuthService(prisma, fastify);

  // POST /register
  fastify.post("/register", {
    schema: {
      body: RegisterDTO
    }
  }, async (request, reply) => {
    try {
      return await authService.register(request.body);
    } catch (e: any) {
      return reply.code(400).send({ error: e.message });
    }
  });

  // POST /login
  fastify.post("/login", {
    schema: {
      body: LoginDTO
    }
  }, async (request, reply) => {
    try {
      return await authService.login(request.body);
    } catch (e: any) {
      return reply.code(401).send({ error: e.message });
    }
  });

  // POST /refresh
  fastify.post("/refresh", {
    schema: { body: Type.Object({ refreshToken: Type.String() }) }
  }, async (request, reply) => {
    try {
      return await authService.refreshToken((request.body as any).refreshToken);
    } catch (e: any) {
      return reply.code(401).send({ error: e.message });
    }
  });

  // DELETE /logout (stateless — client drops token; mark refresh invalid if using DB)
  fastify.delete("/logout", async (request, reply) => {
    return { message: "Logged out" };
  });
};

export default authRoutes;
