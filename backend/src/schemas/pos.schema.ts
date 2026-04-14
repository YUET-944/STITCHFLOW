import { Type } from "@sinclair/typebox";
import { GarmentStage } from "@prisma/client";

export const POSActionDTO = Type.Object({
  basePrice: Type.Number(),
  advancePaid: Type.Number(),
  garmentType: Type.String(),
  deliveryDate: Type.Optional(Type.String())
});

export const AdvanceStageDTO = Type.Object({
  newStage: Type.Enum(GarmentStage)
});
