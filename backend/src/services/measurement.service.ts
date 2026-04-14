import { PrismaClient } from "@prisma/client";

export class MeasurementService {
  constructor(private prisma: PrismaClient) {}

  /**
   * GATE 2: Link Existence Check
   * Explicitly ensures the tailor has an active link with the client.
   * If this fails, no db modification takes place.
   */
  async assertActiveLink(tailorId: string, clientId: string) {
    const link = await this.prisma.tailorClientLink.findFirst({
      where: { tailor_id: tailorId, client_id: clientId, is_active: true }
    });

    if (!link) {
      throw new Error("LINK_NOT_FOUND");
    }
  }

  async saveMeasurement(tailorId: string, clientId: string, data: any) {
    // Validate Gate 2
    await this.assertActiveLink(tailorId, clientId);

    // Gate 3: Range Validation (#65)
    for (const [key, val] of Object.entries(data)) {
      if (typeof val === 'number' && val < 0) throw new Error(`INVALID_VALUE: ${key} cannot be negative`);
    }

    const measurementId = `SF-M-${tailorId.substring(0,4).toUpperCase()}-${clientId.substring(0,4).toUpperCase()}-${Date.now()}`;

    // Parent ID Validation (#61)
    // If incoming parent_id exists, verify it belongs to this client+tailor
    if (data.parent_id) {
       const p = await this.prisma.measurement.findUnique({ where: { id: data.parent_id } });
       if (!p || p.client_id !== clientId || p.tailor_id !== tailorId) {
         throw new Error("INVALID_PARENT_ID");
       }
    }

    // Get the previous latest measurement if parent_id not provided
    const lastMeasurement = await this.prisma.measurement.findFirst({
      where: { client_id: clientId, tailor_id: tailorId, is_current: true },
    });

    const version = lastMeasurement ? lastMeasurement.version + 1 : 1;
    const parent_id = data.parent_id || (lastMeasurement ? lastMeasurement.id : null);

    // Use transaction to preserve append-only history integrity
    const measurement = await this.prisma.$transaction(async (tx) => {
      // 1. Invalidate previous measurements
      await tx.measurement.updateMany({
        where: { client_id: clientId, tailor_id: tailorId },
        data: { is_current: false }
      });

      // 2. Insert new record
      return await tx.measurement.create({
        data: {
          id: measurementId,
          client_id: clientId,
          tailor_id: tailorId,
          version,
          parent_id,
          is_current: true,
          neck: data.neck,
          chest: data.chest,
          waist: data.waist,
          hips: data.hips,
          shoulder_width: data.shoulder_width || data.shoulder,
          sleeve_length: data.sleeve_length || data.sleeve,
          inseam: data.inseam,
          thigh: data.thigh,
          shirt_length: data.shirt_length,
          pant_length: data.pant_length || data.trouser_length,
          custom_notes: data.custom_notes
        }
      });
    });

    return measurement;
  }

  async getMeasurementHistory(clientId: string, requestingUserId: string, requestingUserRole: string) {
    // If requestingUser is a Tailor, verify link exists
    if (requestingUserRole === "TAILOR") {
      await this.assertActiveLink(requestingUserId, clientId);
      return await this.prisma.measurement.findMany({
        where: { client_id: clientId, tailor_id: requestingUserId },
        orderBy: { recorded_at: 'desc' }
      });
    } else if (requestingUserRole === "CLIENT" && clientId !== requestingUserId) {
      throw new Error("FORBIDDEN: Can only view own measurements");
    }

    return await this.prisma.measurement.findMany({
      where: { client_id: clientId },
      orderBy: { recorded_at: 'desc' }
    });
  }
}
