# Network Server API Reference
**Source of truth for the iOS embedded HTTPS server implemented in `NetworkServer`**

---

## Overview

The iOS app exposes a local HTTPS API for the macOS CLI.

- **Protocol:** HTTPS (TLS 1.3)
- **Host/Port:** Provided by the QR payload generated in the iOS app
- **Default path prefix:** `/api/v1`
- **Encoding:** JSON with ISO-8601 dates

The server is implemented in `iOS Health Sync App/iOS Health Sync App/Services/Network/NetworkServer.swift`.

---

## Authentication Model

Authentication is split into two phases:

1. **Pairing phase (`POST /api/v1/pair`)**
   - Uses a short-lived pairing code from the QR payload.
   - Does **not** require `Authorization` header.
2. **Data/API phase (all other routes)**
   - Requires `Authorization: Bearer <token>`.
   - Header field name is treated case-insensitively (`Authorization` or `authorization`).

Transport security is reinforced on the CLI side using certificate fingerprint pinning.

---

## Endpoints

### `POST /api/v1/pair`

Creates an API token from an active pairing session.

**Request body**

```json
{
  "code": "ABCD2345",
  "clientName": "My Mac"
}
```

**200 OK**

```json
{
  "token": "<opaque token>",
  "expiresAt": "2026-02-19T22:30:00Z"
}
```

**400 Bad Request**

Plain-text message with pairing failure reason (invalid/expired code, too many attempts, no pending session, invalid payload format).

---

### `GET /api/v1/status`

Returns server and sharing status.

**Required header**

- `Authorization: Bearer <token>`

**200 OK**

```json
{
  "status": "ok",
  "version": "1",
  "deviceName": "HealthSync-AB12",
  "enabledTypes": ["steps", "heartRate"],
  "serverTime": "2026-02-19T22:30:00Z"
}
```

---

### `GET /api/v1/health/types`

Returns the currently enabled HealthKit data types.

**Required header**

- `Authorization: Bearer <token>`

**200 OK**

```json
{
  "enabledTypes": ["steps", "heartRate", "sleepAnalysis"]
}
```

---

### `POST /api/v1/health/data`

Fetches HealthKit samples for a date range and selected types.

**Required header**

- `Authorization: Bearer <token>`

**Request body**

```json
{
  "startDate": "2026-02-01T00:00:00Z",
  "endDate": "2026-02-19T23:59:59Z",
  "types": ["steps", "heartRate"],
  "limit": 1000,
  "offset": 0
}
```

`limit` and `offset` are optional.

- `limit` default: `1000`
- `limit` max: `10000`
- `offset` minimum effective value: `0`

**200 OK**

```json
{
  "status": "ok",
  "samples": [
    {
      "id": "B4C7A671-530D-4B2E-9D8D-C2D037C4578A",
      "type": "steps",
      "value": 8421,
      "unit": "count",
      "startDate": "2026-02-18T00:00:00Z",
      "endDate": "2026-02-18T23:59:59Z",
      "sourceName": "iPhone",
      "metadata": null
    }
  ],
  "message": null,
  "hasMore": false,
  "returnedCount": 1
}
```

**423 Locked**

Returned when protected data is unavailable (for example, device locked).

```json
{
  "status": "locked",
  "samples": [],
  "message": "Device is locked",
  "hasMore": false,
  "returnedCount": 0
}
```

---

## Common Error Responses

| Status | Reason | Body format |
|---|---|---|
| `400` | Invalid request body, empty types, invalid date range, invalid limit | `text/plain` |
| `401` | Missing or invalid token | `text/plain` |
| `403` | Requested types are not enabled in server config | `text/plain` |
| `404` | Unknown route | `text/plain` |
| `408` | Request timeout/incomplete request | `text/plain` |
| `413` | Request body too large | `text/plain` |
| `423` | Protected data unavailable | `application/json` |
| `429` | Rate limit exceeded | `text/plain` |

---

## Request Parsing and Limits

The HTTP parser enforces:

- **Max headers:** `16 KB`
- **Max body:** `1 MB`
- **Max request duration:** `10 s`
- **Rate limit:** `60 requests/minute` per token

Header names are normalized to lowercase during parsing.

---

## Lifecycle and Reliability Notes

`NetworkServer.start()` is concurrency-safe:

- Parallel start calls share a single startup path.
- Waiters resume together after startup success/failure.
- `stop()` can cancel an in-flight startup.

This avoids listener races under concurrent UI or task triggers.

---

## Example Workflow (cURL)

```bash
# 1) Pair
curl -k -X POST "https://<host>:<port>/api/v1/pair" \
  -H "Content-Type: application/json" \
  -d '{"code":"ABCD2345","clientName":"My Mac"}'

# 2) Call protected endpoint (header name can be lowercase)
curl -k "https://<host>:<port>/api/v1/status" \
  -H "authorization: Bearer <token>"
```

> Use the CLI in production flows. It applies certificate fingerprint pinning and structured error handling.
