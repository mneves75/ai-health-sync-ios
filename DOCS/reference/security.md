# Security Reference
**Technical specifications for iOS Health Sync security implementation**

---

## Overview

iOS Health Sync implements a zero-trust security model with mutual TLS (mTLS) authentication. No data leaves your local network; all communication is peer-to-peer between your iPhone and Mac.

---

## Security Architecture

```
┌─────────────────┐         mTLS (TLS 1.3)        ┌─────────────────┐
│   macOS CLI     │◄────────────────────────────►│   iOS App       │
│                 │                               │                 │
│ • Client Cert   │         Local Network         │ • Server Cert   │
│ • CA Cert       │         (No Internet)         │ • CA Cert       │
│ • Private Key   │                               │ • Private Key   │
└─────────────────┘                               └─────────────────┘
        │                                                 │
        ▼                                                 ▼
   ┌─────────┐                                      ┌─────────┐
   │Keychain │                                      │Keychain │
   │Services │                                      │Services │
   └─────────┘                                      └─────────┘
```

---

## Certificate Specifications

### Certificate Authority (CA)

| Property | Value |
|----------|-------|
| Algorithm | ECDSA P-256 |
| Signature | SHA-256 |
| Validity | 5 years |
| Key Usage | Certificate Sign, CRL Sign |
| Basic Constraints | CA:TRUE |

### Server Certificate (iOS App)

| Property | Value |
|----------|-------|
| Algorithm | ECDSA P-256 |
| Signature | SHA-256 |
| Validity | 1 year |
| Key Usage | Digital Signature, Key Encipherment |
| Extended Key Usage | TLS Web Server Authentication |
| Subject Alternative Name | IP Address (dynamic) |

### Client Certificate (macOS CLI)

| Property | Value |
|----------|-------|
| Algorithm | ECDSA P-256 |
| Signature | SHA-256 |
| Validity | 1 year |
| Key Usage | Digital Signature |
| Extended Key Usage | TLS Web Client Authentication |
| Subject | CN=healthsync-client |

---

## TLS Configuration

### Protocol
- **Minimum Version:** TLS 1.3
- **Maximum Version:** TLS 1.3

### Cipher Suites (in order of preference)
1. `TLS_AES_256_GCM_SHA384`
2. `TLS_CHACHA20_POLY1305_SHA256`
3. `TLS_AES_128_GCM_SHA256`

### Key Exchange
- ECDHE with P-256 curve
- Perfect Forward Secrecy (PFS) enabled

---

## Key Storage

### macOS (CLI)

| Item | Storage Location |
|------|------------------|
| Client Private Key | Keychain Services (login keychain) |
| Client Certificate | Keychain Services (login keychain) |
| CA Certificate | Keychain Services (login keychain) |
| Server Address | `~/.config/healthsync/config.json` |

**Keychain Access:**
```bash
# View stored items
security find-certificate -a -c "healthsync"

# Access requires user authentication
security set-key-partition-list -S apple-tool:,apple: -k "" ~/Library/Keychains/login.keychain-db
```

### iOS (App)

| Item | Storage Location |
|------|------------------|
| Server Private Key | Keychain Services (kSecAttrAccessibleWhenUnlocked) |
| Server Certificate | Keychain Services |
| CA Certificate | Keychain Services |
| Client Certificates | Keychain Services (trusted clients) |

**Keychain Attributes:**
- `kSecAttrAccessible`: `kSecAttrAccessibleWhenUnlocked`
- `kSecAttrSynchronizable`: `false` (not synced to iCloud)
- `kSecAttrAccessControl`: Requires device unlock

---

## Certificate Generation

Certificates are generated during the pairing process:

```swift
// iOS: Generate key pair
let privateKey = P256.KeyAgreement.PrivateKey()
let publicKey = privateKey.publicKey

// Create self-signed CA (first pairing only)
let ca = Certificate.create(
    subject: "healthsync-ca",
    issuer: "healthsync-ca",
    publicKey: caPublicKey,
    privateKey: caPrivateKey,
    isCA: true,
    validity: .years(5)
)

// Create server certificate
let serverCert = Certificate.create(
    subject: "healthsync-server",
    issuer: "healthsync-ca",
    publicKey: serverPublicKey,
    privateKey: caPrivateKey,
    isCA: false,
    validity: .years(1),
    san: [.ipAddress(localIP)]
)

// Create client certificate
let clientCert = Certificate.create(
    subject: "healthsync-client",
    issuer: "healthsync-ca",
    publicKey: clientPublicKey,
    privateKey: caPrivateKey,
    isCA: false,
    validity: .years(1)
)
```

---

## QR Code Contents

The QR code contains a JSON payload with:

```json
{
  "version": 1,
  "server": {
    "host": "192.168.1.100",
    "port": 8443
  },
  "certificates": {
    "ca": "-----BEGIN CERTIFICATE-----\n...",
    "client": "-----BEGIN CERTIFICATE-----\n...",
    "client_key": "-----BEGIN PRIVATE KEY-----\n..."
  },
  "fingerprint": "sha256:AB12CD34..."
}
```

**Security measures:**
- QR code is displayed only on-device
- Contains one-time use client certificate
- Certificate is bound to specific CA
- Fingerprint allows verification

---

## Network Security

### SSRF Protection

The server rejects requests that could cause SSRF:
- Only accepts connections from local network (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
- Blocks requests to localhost/127.0.0.1
- No HTTP redirects followed
- No external URL fetching

### Request Validation

```swift
// Validate request origin
guard request.remoteAddress.isPrivate else {
    throw SecurityError.invalidOrigin
}

// Validate content type
guard request.contentType == .json else {
    throw SecurityError.invalidContentType
}

// Validate request size
guard request.bodySize <= maxRequestSize else {
    throw SecurityError.requestTooLarge
}
```

### Rate Limiting

| Limit | Value | Scope |
|-------|-------|-------|
| Requests/minute | 60 | Per client certificate |
| Concurrent connections | 5 | Per client certificate |
| Failed auth attempts | 5 | Per IP, then 5-min block |

---

## Data Protection

### In Transit
- All data encrypted with TLS 1.3
- Perfect Forward Secrecy ensures past sessions can't be decrypted
- Certificate pinning prevents MITM attacks

### At Rest
- Health data is NOT stored on the server (iOS app)
- Health data is queried from HealthKit on-demand
- CLI can optionally save to local files (user's choice)
- No cloud storage, no analytics, no telemetry

### Memory
- Private keys cleared from memory after use
- Health data cleared after response sent
- No logging of health data values

---

## Threat Model

### Protected Against

| Threat | Mitigation |
|--------|------------|
| Eavesdropping | TLS 1.3 encryption |
| Man-in-the-middle | mTLS certificate validation |
| Replay attacks | TLS session tickets, nonces |
| Certificate theft | Keychain protection, device-bound |
| Unauthorized access | Client certificate required |
| Data exfiltration | Local network only, no cloud |

### Not Protected Against

| Threat | Reason |
|--------|--------|
| Physical device access | Out of scope - device security |
| Compromised device | Assumes device integrity |
| Local network attacks | Assumes trusted network |
| Keychain extraction | Requires device compromise |

---

## Audit Logging

Security events are logged (without sensitive data):

```swift
AuditService.log(
    event: .certificateValidation,
    outcome: .success,
    clientFingerprint: cert.sha256Fingerprint,
    remoteAddress: request.remoteAddress.redacted
)
```

**Logged Events:**
- Certificate validation (success/failure)
- Connection attempts
- Authentication failures
- Rate limit triggers
- Permission checks

**Not Logged:**
- Health data values
- Full IP addresses (last octet redacted)
- Private keys or certificates

---

## Compliance

### Apple Requirements
- Privacy manifest (`PrivacyInfo.xcprivacy`) included
- No tracking or fingerprinting
- HealthKit data usage declared
- Local network usage declared

### Data Handling
- No data leaves user's devices
- No third-party services
- No analytics or telemetry
- User controls all data exports

---

## Security Checklist

For developers extending this project:

- [ ] Never log health data values
- [ ] Never store health data persistently (server-side)
- [ ] Always validate certificates in full chain
- [ ] Always use TLS 1.3 minimum
- [ ] Always store keys in Keychain
- [ ] Never hardcode credentials
- [ ] Never disable certificate validation
- [ ] Always rate-limit authentication attempts

---

## Related Documentation

- **[Security Model](../explanation/security-model.md)** - Conceptual overview
- **[Generate Certificates](../how-to/generate-certificates.md)** - Manual certificate management
- **[Fix Auth Errors](../how-to/fix-auth-errors.md)** - Troubleshooting
- **[Architecture](./architecture.md)** - System overview

---

*Last updated: 2026-01-07*
