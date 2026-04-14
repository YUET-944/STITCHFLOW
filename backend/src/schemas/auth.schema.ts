import { Type } from "@sinclair/typebox";
import { Role } from "@prisma/client";

export const RegisterDTO = Type.Object({
  username: Type.String({ minLength: 3, maxLength: 30, pattern: '^[a-zA-Z0-9_]+$' }),
  password: Type.String({ minLength: 4, maxLength: 100 }),
  email: Type.Optional(Type.String({ format: 'email', maxLength: 255 })),
  role: Type.Enum(Role),
  full_name: Type.String({ minLength: 2, maxLength: 100 }),
  city: Type.Optional(Type.String({ maxLength: 100 })),
  business_name: Type.Optional(Type.String({ maxLength: 100 })),
  specializations: Type.Optional(Type.Array(Type.String())),
  price_min: Type.Optional(Type.Number({ minimum: 0 })),
  price_max: Type.Optional(Type.Number({ minimum: 0 })),
});

export const LoginDTO = Type.Object({
  username: Type.String(),
  password: Type.String(),
});

export const AuthResponseDTO = Type.Object({
  user: Type.Any(),
  accessToken: Type.String(),
  refreshToken: Type.String(),
});
