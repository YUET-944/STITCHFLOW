import Fastify from "fastify";
import { TypeBoxTypeProvider } from "@fastify/type-provider-typebox";
import jwtPlugin from "./plugins/jwt";
import firebasePlugin from "./plugins/firebase";
import authRoutes from "./routes/auth.routes";
import measurementRoutes from "./routes/measurement.routes";
import bookingRoutes from "./routes/booking.routes";
import posRoutes from "./routes/pos.routes";
import searchRoutes from "./routes/search.routes";
import tailorRoutes from "./routes/tailor.routes";
import fastifyCors from "@fastify/cors";
import fastifyRateLimit from "@fastify/rate-limit";
import { prisma } from "./lib/prisma";

const fastify = Fastify({ logger: true }).withTypeProvider<TypeBoxTypeProvider>();

// ── Plugins ──────────────────────────────────────────────────────────────────
fastify.register(jwtPlugin);
fastify.register(firebasePlugin);

fastify.register(fastifyRateLimit, {
  max: parseInt(process.env.MAX_RATE_LIMIT || "100", 10),
  timeWindow: '1 minute',
  allowList: ['127.0.0.1', '10.0.2.2']
});

fastify.register(fastifyCors, {
  origin: (origin: string | undefined, cb: (err: Error | null, allow: boolean) => void) => {
    // Only permit explicitly whitelisted origins
    const allowed = process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000', 'capacitor://localhost'];
    if (!origin || 
        origin.startsWith('http://localhost:') || 
        origin.startsWith('http://127.0.0.1:') ||
        origin.startsWith('http://10.0.2.2') ||
        allowed.includes(origin)) {
      cb(null, true);
      return;
    }
    cb(new Error("CORS origin not allowed"), false);
  },
  methods: ["GET", "POST", "PATCH", "DELETE", "OPTIONS"]
});

// ── Routes ────────────────────────────────────────────────────────────────────
fastify.register(authRoutes,        { prefix: "/api/v1/auth" });
fastify.register(measurementRoutes, { prefix: "/api/v1/measurements" });
fastify.register(bookingRoutes,     { prefix: "/api/v1/orders" });
fastify.register(posRoutes,         { prefix: "/api/v1" });
fastify.register(searchRoutes,      { prefix: "/api/v1/search" });
fastify.register(tailorRoutes,      { prefix: "/api/v1" });

// ── Health ────────────────────────────────────────────────────────────────────
fastify.get("/health", async (request, reply) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return { status: "ok", message: "StitchFlow Anti-Gravity Engine Online ✓" };
  } catch {
    reply.status(500).send({ status: "error" });
  }
});

const start = async () => {
  try {
    await fastify.listen({ port: 3000, host: "0.0.0.0" });
    fastify.log.info("StitchFlow Backend on port 3000");
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();
