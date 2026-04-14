import { Type } from "@sinclair/typebox";

const NonNegativeDecimal = Type.Number({ minimum: 0 });

export const MeasurementDTO = Type.Object({
  clientId: Type.String({ format: "uuid" }),
  neck:           Type.Optional(NonNegativeDecimal),
  chest:          Type.Optional(NonNegativeDecimal),
  waist:          Type.Optional(NonNegativeDecimal),
  hips:           Type.Optional(NonNegativeDecimal),
  shoulder_width: Type.Optional(NonNegativeDecimal),
  sleeve_length:  Type.Optional(NonNegativeDecimal),
  inseam:         Type.Optional(NonNegativeDecimal),
  thigh:          Type.Optional(NonNegativeDecimal),
  shirt_length:   Type.Optional(NonNegativeDecimal),
  pant_length:    Type.Optional(NonNegativeDecimal),
  custom_notes:   Type.Optional(Type.String({ maxLength: 500 })),
  parent_id:      Type.Optional(Type.String()),
});
