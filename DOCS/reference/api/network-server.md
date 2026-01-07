# Network Server API Reference
**Complete API documentation for the iOS app's embedded HTTPS server**

---

## Overview

The iOS Health Sync app runs an embedded HTTPS server that accepts requests from the macOS CLI. All endpoints require mTLS authentication.

**Base URL:** `https://<iphone-ip>:8443`
**Protocol:** HTTPS with mTLS (TLS 1.3)
**Content-Type:** `application/json`

---

## Authentication

All requests must include a valid client certificate. The server validates:

1. Certificate is signed by the paired CA
2. Certificate is not expired
3. Certificate is not revoked

Requests without valid certificates receive `401 Unauthorized`.

---

## Endpoints

### Health Check

#### `GET /health`

Check server status and connectivity.

**Request:**
```bash
curl --cert client.pem --key client-key.pem --cacert ca.pem \
  https://192.168.1.100:8443/health
```

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime": 3600,
  "timestamp": "2026-01-07T10:30:00Z"
}
```

**Status Codes:**
| Code | Description |
|------|-------------|
| 200 | Server is healthy |
| 503 | Server is starting up |

---

### Fetch Health Data

#### `GET /health-data`

Retrieve HealthKit data for specified types and date range.

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `types` | string | Yes | Comma-separated list of health data types |
| `start` | string | Yes | Start date (ISO 8601: `YYYY-MM-DD` or `YYYY-MM-DDTHH:MM:SSZ`) |
| `end` | string | No | End date (defaults to now) |
| `limit` | integer | No | Maximum records per type (default: 1000) |
| `format` | string | No | Response format: `json` (default) or `csv` |

**Supported Types:**

| Type | HealthKit Identifier | Unit |
|------|---------------------|------|
| `steps` | `HKQuantityTypeIdentifierStepCount` | count |
| `heart_rate` | `HKQuantityTypeIdentifierHeartRate` | bpm |
| `active_energy` | `HKQuantityTypeIdentifierActiveEnergyBurned` | kcal |
| `distance` | `HKQuantityTypeIdentifierDistanceWalkingRunning` | m |
| `flights` | `HKQuantityTypeIdentifierFlightsClimbed` | count |
| `sleep` | `HKCategoryTypeIdentifierSleepAnalysis` | category |
| `weight` | `HKQuantityTypeIdentifierBodyMass` | kg |
| `height` | `HKQuantityTypeIdentifierHeight` | m |
| `blood_oxygen` | `HKQuantityTypeIdentifierOxygenSaturation` | % |
| `respiratory_rate` | `HKQuantityTypeIdentifierRespiratoryRate` | breaths/min |

**Request:**
```bash
curl --cert client.pem --key client-key.pem --cacert ca.pem \
  "https://192.168.1.100:8443/health-data?types=steps,heart_rate&start=2026-01-01&end=2026-01-07"
```

**Response (JSON):**
```json
{
  "data": {
    "steps": [
      {
        "value": 8432,
        "unit": "count",
        "start_date": "2026-01-01T00:00:00Z",
        "end_date": "2026-01-01T23:59:59Z",
        "source": "iPhone",
        "device": "iPhone 16 Pro"
      }
    ],
    "heart_rate": [
      {
        "value": 72,
        "unit": "bpm",
        "start_date": "2026-01-01T08:30:00Z",
        "end_date": "2026-01-01T08:30:00Z",
        "source": "Apple Watch",
        "device": "Apple Watch Series 10"
      }
    ]
  },
  "metadata": {
    "query_time_ms": 245,
    "total_records": 156,
    "types_requested": ["steps", "heart_rate"],
    "date_range": {
      "start": "2026-01-01T00:00:00Z",
      "end": "2026-01-07T23:59:59Z"
    }
  }
}
```

**Response (CSV):**
```csv
type,value,unit,start_date,end_date,source,device
steps,8432,count,2026-01-01T00:00:00Z,2026-01-01T23:59:59Z,iPhone,iPhone 16 Pro
heart_rate,72,bpm,2026-01-01T08:30:00Z,2026-01-01T08:30:00Z,Apple Watch,Apple Watch Series 10
```

**Status Codes:**
| Code | Description |
|------|-------------|
| 200 | Success |
| 400 | Invalid parameters |
| 401 | Authentication failed |
| 403 | HealthKit permission denied |
| 500 | Server error |

---

### Get Available Types

#### `GET /types`

List all available HealthKit data types and their permissions.

**Request:**
```bash
curl --cert client.pem --key client-key.pem --cacert ca.pem \
  https://192.168.1.100:8443/types
```

**Response:**
```json
{
  "types": [
    {
      "id": "steps",
      "name": "Step Count",
      "healthkit_type": "HKQuantityTypeIdentifierStepCount",
      "unit": "count",
      "permission": "authorized"
    },
    {
      "id": "heart_rate",
      "name": "Heart Rate",
      "healthkit_type": "HKQuantityTypeIdentifierHeartRate",
      "unit": "bpm",
      "permission": "authorized"
    },
    {
      "id": "sleep",
      "name": "Sleep Analysis",
      "healthkit_type": "HKCategoryTypeIdentifierSleepAnalysis",
      "unit": "category",
      "permission": "not_determined"
    }
  ]
}
```

**Permission Values:**
| Value | Description |
|-------|-------------|
| `authorized` | User granted read access |
| `denied` | User explicitly denied access |
| `not_determined` | User hasn't been asked yet |

> **Note:** Due to Apple privacy restrictions, `denied` and `not_determined` may appear the same. The app cannot distinguish between them.

---

### Get Server Info

#### `GET /info`

Get server configuration and device information.

**Request:**
```bash
curl --cert client.pem --key client-key.pem --cacert ca.pem \
  https://192.168.1.100:8443/info
```

**Response:**
```json
{
  "server": {
    "version": "1.0.0",
    "build": "100",
    "protocol_version": "1"
  },
  "device": {
    "name": "iPhone 16 Pro",
    "model": "iPhone17,1",
    "system_version": "iOS 26.0"
  },
  "healthkit": {
    "available": true,
    "authorized_types": 8,
    "total_types": 12
  },
  "network": {
    "address": "192.168.1.100",
    "port": 8443,
    "interface": "en0"
  }
}
```

---

### Ping

#### `GET /ping`

Simple connectivity test.

**Request:**
```bash
curl --cert client.pem --key client-key.pem --cacert ca.pem \
  https://192.168.1.100:8443/ping
```

**Response:**
```json
{
  "pong": true,
  "timestamp": "2026-01-07T10:30:00Z"
}
```

---

## Error Responses

All errors return JSON with consistent structure:

```json
{
  "error": {
    "code": "INVALID_DATE_RANGE",
    "message": "Start date must be before end date",
    "details": {
      "start": "2026-01-07",
      "end": "2026-01-01"
    }
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_PARAMETERS` | 400 | Missing or malformed parameters |
| `INVALID_DATE_RANGE` | 400 | Date range is invalid |
| `INVALID_TYPE` | 400 | Unknown health data type |
| `UNAUTHORIZED` | 401 | Certificate validation failed |
| `FORBIDDEN` | 403 | HealthKit permission denied |
| `NOT_FOUND` | 404 | Endpoint not found |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |
| `HEALTHKIT_ERROR` | 500 | HealthKit query failed |

---

## Rate Limiting

The server implements rate limiting to protect device resources:

| Limit | Value |
|-------|-------|
| Requests per minute | 60 |
| Concurrent connections | 5 |
| Max request body size | 1 MB |
| Query timeout | 30 seconds |

Rate limit headers:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 58
X-RateLimit-Reset: 1704624000
```

---

## Request Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Accept` | No | Response format (`application/json` or `text/csv`) |
| `X-Request-ID` | No | Client-provided request ID for tracing |

---

## Response Headers

| Header | Description |
|--------|-------------|
| `Content-Type` | Response MIME type |
| `X-Request-ID` | Echo of client request ID or generated UUID |
| `X-Response-Time` | Server processing time in ms |

---

## TLS Configuration

**Required:**
- TLS 1.3
- Client certificate (mTLS)
- Server certificate validation

**Cipher Suites:**
- TLS_AES_256_GCM_SHA384
- TLS_CHACHA20_POLY1305_SHA256
- TLS_AES_128_GCM_SHA256

---

## Example: Complete Workflow

```bash
# 1. Check connectivity
healthsync ping

# 2. List available types
healthsync types

# 3. Fetch specific data
healthsync fetch --types steps,heart_rate --start 2026-01-01 --format json

# 4. Export to CSV
healthsync fetch --types steps --start 2026-01-01 --output steps.csv
```

---

## Related Documentation

- **[Architecture](../architecture.md)** - System overview
- **[Data Flows](../data-flows.md)** - Request/response lifecycle
- **[Security](../security.md)** - mTLS and certificate details
- **[HealthKit Service API](./healthkit-service-api.md)** - Internal HealthKit wrapper

---

*Last updated: 2026-01-07*
