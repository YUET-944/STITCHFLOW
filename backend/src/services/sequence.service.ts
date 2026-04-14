import { PrismaClient, Role } from "@prisma/client";

export class SequenceService {
  constructor(private prisma: PrismaClient) {}

  async generateReadableId(role: Role, city: string): Promise<string> {
    const prefix = role === "TAILOR" ? "TR" : "CL";
    const cityNormalized = (city || 'Unknown')
      .replace(/[^a-zA-Z0-9]/g, "")
      .substring(0, 10)
      .toUpperCase();
    const seqId = `${prefix}_${cityNormalized}`;

    /**
     * Capacity Gate Serialized Transaction
     * Enforces strict atomic sequence generation using SELECT FOR UPDATE
     */
    const nextVal = await this.prisma.$transaction(async (tx) => {
      // Create if not exists in a raw query because Prisma upsert doesn't lock well for purely sequential increments safely
      await tx.$executeRaw`
        INSERT INTO "sequences" (id, prefix, last_value)
        VALUES (${seqId}, ${prefix}, 0)
        ON CONFLICT (id) DO NOTHING
      `;

      // Select for update locks the row
      const seq: any[] = await tx.$queryRaw`
        SELECT last_value FROM "sequences"
        WHERE id = ${seqId}
        FOR UPDATE
      `;

      const next = seq[0].last_value + 1;

      // Update the sequence
      await tx.$executeRaw`
        UPDATE "sequences" 
        SET last_value = ${next}
        WHERE id = ${seqId}
      `;

      return next;
    });

    const padded = nextVal.toString().padStart(3, "0");
    return `${prefix}-${cityNormalized}-${padded}`; // e.g. TR-KARACHI-001
  }
}
