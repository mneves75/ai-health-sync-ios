# Security Reference
**Technical reference for the current security model used by HealthSync Helper App**

---

## Security Posture

The project uses a local-first security model with layered controls:

- TLS 1.3 for transport confidentiality and integrity
- Certificate fingerprint pinning in the macOS CLI (MITM resistance)
- Pairing-code exchange to bootstrap trust
- Bearer token authorization for protected API routes
- Audit logging with sensitive-data redaction rules

No cloud service is required for data exchange.

---

## Trust Boundaries

1. **iOS app boundary**
   - Owns HealthKit access and embedded HTTPS server.
2. **macOS CLI boundary**
   - Connects over LAN and validates pinned server fingerprint.
3. **Local network boundary**
   - Untrusted by default; protected by TLS + pinning + token auth.

---

## Transport Security

### TLS Configuration

- Minimum protocol: **TLS 1.3**
- Server identity generated and loaded by `CertificateService`
- iOS server listens via `NWListener` with TLS options

### Fingerprint Pinning (CLI)

The CLI computes SHA-256 fingerprint from the presented server certificate and compares it to the fingerprint captured during pairing.

If mismatch occurs, the connection is rejected.

---

## Authentication and Authorization

### Pairing Bootstrap

`POST /api/v1/pair` accepts a short-lived code from QR payload and returns a token.

Pairing protections:

- Pairing code TTL: **5 minutes**
- Max failed attempts: **5** per pending session
- Constant-time code comparison to reduce timing side channels

### API Authorization

Protected routes require:

- `Authorization: Bearer <token>`

Token behavior:

- Token is hashed before persistence
- Token expiry is enforced server-side
- `lastSeenAt` is updated on valid use

Header parsing is case-insensitive for field names.

---

## Request Hardening

`NetworkServer` enforces:

- Rate limit: **60 req/min** per token
- Header size cap: **16 KB**
- Body size cap: **1 MB**
- Request duration timeout: **10 s**
- Explicit status handling for `400`, `401`, `403`, `404`, `408`, `413`, `423`, `429`

---

## Secret and Key Material Storage

### iOS

- TLS key/certificate stored in Keychain
- Private key accessibility: `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
- Secure Enclave preferred when available (fallback to software key)

### macOS CLI

- Access token stored in Keychain (`healthsync-cli` service)
- Server config/fingerprint stored in local config file

---

## Logging and Audit

### Audit Events

`AuditService` records structured events (for example `auth.pair`, `security.unauthorized_access`, `data.read`, `api.request`).

Retention policy:

- 90-day retention with periodic purge

### Sensitive Data Handling

- Pairing QR secret code is **not** logged
- Health sample payload values are not logged to audit stream
- Pairing client name is anonymized before persistence (`Client-XXXXXXXX`)

---

## Latest Hardening (Unreleased)

- Authorization header compatibility fixed (`Authorization` / `authorization`)
- Concurrent server startup race removed via coordinated `start()` gate
- Pairing QR code secret removed from app logs
- Regression tests added for both auth-header and concurrent-start scenarios

---

## Operational Recommendations

- Prefer CLI workflows over raw curl for certificate pinning and safer defaults
- Rotate pairings (`revokeAll`) when device ownership changes
- Keep app and CLI updated together to avoid protocol drift
