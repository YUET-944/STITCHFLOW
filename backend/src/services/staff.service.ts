import { PrismaClient } from "@prisma/client";

export class StaffService {
  constructor(private prisma: PrismaClient) {}

  /** Add staff profile */
  async addStaff(tailorId: string, data: { name: string; specialty: string; phone: string }) {
    return this.prisma.staffProfile.create({
      data: {
        tailor_id: tailorId,
        name: data.name,
        specialty: data.specialty,
        phone: data.phone,
      }
    });
  }

  /** List all staff with accurate performance metrics from persisted DB counters */
  async listStaff(tailorId: string) {
    const staff = await this.prisma.staffProfile.findMany({
      where: { tailor_id: tailorId },
      include: {
        assignments: {
          select: {
            id: true,
            delivery_stage: true,
          }
        }
      }
    });

    return staff.map(s => {
      const totalAssigned = s.assignments.length;
      const completed = s.assignments.filter(
        a => a.delivery_stage === "READY" || a.delivery_stage === "QC_PASSED"
      ).length;

      // Use persisted DB counters for on-time rate (updated by POS/stage advancement)
      // total_completed_on_time is incremented by the stage service when READY is reached on time
      const onTimeRate = completed > 0
        ? Math.round((s.total_completed_on_time / Math.max(completed, 1)) * 100)
        : 0;

      return {
        id: s.id,
        name: s.name,
        specialty: s.specialty,
        phone: s.phone,
        is_active: s.is_active,
        total_assigned: totalAssigned,
        completed,
        on_time_rate: onTimeRate,
        total_on_time: s.total_completed_on_time,
      };
    });
  }

  /** Assign staff master to garment */
  async assignStaff(tailorId: string, garmentId: string, staffId: string) {
    const garment = await this.prisma.orderGarment.findUnique({
      where: { id: garmentId },
      include: { order: true }
    });
    if (!garment || garment.order.tailor_id !== tailorId) throw new Error("GARMENT_NOT_FOUND");

    const staff = await this.prisma.staffProfile.findUnique({ where: { id: staffId } });
    if (!staff || staff.tailor_id !== tailorId) throw new Error("STAFF_NOT_FOUND");

    return this.prisma.orderGarment.update({
      where: { id: garmentId },
      data: { staff_master_id: staffId }
    });
  }

  /** Update staff active status */
  async toggleStaff(tailorId: string, staffId: string, isActive: boolean) {
    const staff = await this.prisma.staffProfile.findUnique({ where: { id: staffId } });
    if (!staff || staff.tailor_id !== tailorId) throw new Error("STAFF_NOT_FOUND");
    return this.prisma.staffProfile.update({ where: { id: staffId }, data: { is_active: isActive } });
  }
}
