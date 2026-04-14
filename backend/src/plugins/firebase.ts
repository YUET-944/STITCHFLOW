import fp from "fastify-plugin";
import * as admin from "firebase-admin";

export default fp(async (fastify, opts) => {
  // If no credentials are provided, we mock firebase validation for local dev
  const mockFirebase = process.env.MOCK_FIREBASE === "true";
  
  if (!mockFirebase && admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault() 
    });
  }

  fastify.decorate("verifyFirebaseToken", async (idToken: string) => {
    if (mockFirebase) {
      return {
        uid: "mock-uid-" + Math.random().toString(36).substr(2, 9),
        phone_number: "+923000000000" // Hardcoded mock phone
      };
    }
    return await admin.auth().verifyIdToken(idToken);
  });
});

declare module "fastify" {
  interface FastifyInstance {
    verifyFirebaseToken: (idToken: string) => Promise<{uid: string, phone_number?: string}>;
  }
}
