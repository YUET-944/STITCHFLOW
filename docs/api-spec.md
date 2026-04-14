# StitchFlow API Specification Contract

This document acts as the definitive contract between the Flutter Frontend and the NodeJS/Fastify Backend. Currently, the API follows REST patterns.

## Current Architecture Status

**Base Protocol**: HTTP / JSON
**Authentication**: Bearer JWT passed in `Authorization: Bearer <token>`
**Current Response Wrapper**: Unwrapped (Direct object returns or `{ error: string }` on failure) *[Scheduled for standard wrapping]*

---

## 1. Authentication (`/auth`)

### POST `/auth/register`
Creates a new Client or Tailor account.
- **Auth Required**: No
- **Payload**:
  ```json
  {
    "role": "TAILOR" | "CLIENT",
    "full_name": "string",
    "username": "string",
    "password": "string(min:6)",
    "email": "string(optional)",
    "city": "string(optional)",
    "business_name": "string(optional, tailor-only)",
    "specializations": ["string(optional)"],
    "price_min": "number(optional)",
    "price_max": "number(optional)"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "accessToken": "string",
    "refreshToken": "string",
    "user": {
      "id": "uuid",
      "readable_id": "string",
      "role": "string",
      "full_name": "string",
      "username": "string",
      "city": "string(optional)",
      "tailor_profile": { ...optional }
    }
  }
  ```

### POST `/auth/login`
- **Auth Required**: No
- **Payload**: `{ "username": "string", "password": "string" }`
- **Response** (200 OK): Same as Register.

### POST `/auth/refresh`
- **Auth Required**: No
- **Payload**: `{ "refreshToken": "string" }`
- **Response** (200 OK): `{ "accessToken": "string" }`

### DELETE `/auth/logout`
- **Response** (200 OK): `{ "message": "Logged out" }`

---

## 2. Search & Discovery (`/search`)

### GET `/search/track`
Tracking order details anonymously.
- **Auth Required**: No
- **Query Params**: `?id=SF-O-XXXX` or `?id=CL-XXXXX`
- **Response** (200 OK):
  ```json
  {
    "client_first_name": "string",
    "readable_id": "string",
    "has_active_order": boolean,
    "order": { ... } | null
  }
  ```

### GET `/search/tailors`
Find tailors based on filters.
- **Auth Required**: Optional
- **Query Params**: `city`, `specialization`, `availability`, `price_min`, `price_max`, `limit`
- **Response** (200 OK): Array of Tailor Objects mapped with `city`.

---

## 3. Booking & Orders (`/orders`)

### POST `/orders`
Client creates booking.
- **Auth Required**: Yes (`CLIENT` only)
- **Payload**: 
  ```json
  {
    "tailor_id": "uuid",
    "garments": [{ "type": "string" }],
    ...
  }
  ```

### GET `/orders/tailor/queue`
- **Auth Required**: Yes (`TAILOR` only)
- **Response** (200 OK): Array of pending/in-progress Order Objects.

### GET `/orders/client/mine`
- **Auth Required**: Yes (`CLIENT` only)
- **Response** (200 OK): Array of Client's Order Objects.

### PATCH `/orders/:orderId/approve` | `/reject` | `/cancel`
Changes order booking status.

---

## 4. Measurement Vault (`/measurements`)

### POST `/measurements`
Records new measurement (versioned history).
- **Auth Required**: Yes (`TAILOR` only)
- **Payload**: Measurement details targeting a `clientId`.

### GET `/measurements/vault/:clientId`
Retrieve the measurement history and current verified body measurements.
- **Auth Required**: Yes (Either the client themselves, or a Tailor with an active linked order)

---

## Standardization Target (Future State Roadmap)

This API is currently scheduled to migrate to the following universally-wrapped standard:

**Success Response (2XX):**
```json
{
  "success": true,
  "data": { ...any },
  "error": null
}
```

**Error Response (4XX / 500):**
```json
{
  "success": false,
  "data": null,
  "error": "STANDARDIZED_ERROR_CODE",
  "message": "Human readable message"
}
```
