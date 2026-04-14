import { Type } from "@sinclair/typebox";

// Valid garment types must match the service-level VALID_GARMENTS array
const VALID_GARMENT_TYPES = [
  "SUIT", "SHIRT", "TROUSER", "KAMEEZ", "SHALWAR",
  "WAISTCOAT", "SHERWANI",
] as const;

export const CreateBookingDTO = Type.Object({
  tailor_id:           Type.String({ format: "uuid" }),
  preferredDateStart:  Type.String({ format: "date-time" }),
  preferredDateEnd:    Type.String({ format: "date-time" }),
  specialInstructions: Type.Optional(Type.String({ maxLength: 1000 })),
  garments: Type.Array(
    Type.Union(VALID_GARMENT_TYPES.map(g => Type.Literal(g))),
    { minItems: 1, maxItems: 20 }
  ),
});
