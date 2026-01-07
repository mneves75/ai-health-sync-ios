# Fix Authentication Errors: Resolve mTLS and Certificate Issues
**Troubleshoot certificate-based authentication failures**

---

**Time:** 15-30 minutes
**Difficulty:** Intermediate
**Prerequisites:**
- [ ] Devices previously paired
- [ ] Basic understanding of TLS certificates
- [ ] CLI installed on Mac

---

## Overview

iOS Health Sync uses mutual TLS (mTLS) for authentication. Both the iPhone (server) and Mac (client) must present valid certificates. This guide helps resolve authentication failures.

---

## Quick Diagnosis

```bash
# Check certificate status
healthsync cert info
```

**Healthy output:**
```
Client Certificate:
  Subject: healthsync-client
  Issuer: healthsync-ca
  Valid: 2026-01-07 to 2027-01-07
  Status: Valid

Server Certificate (cached):
  Subject: healthsync-server
  Issuer: healthsync-ca
  Valid: 2026-01-07 to 2027-01-07
  Status: Valid

CA Certificate:
  Subject: healthsync-ca
  Valid: 2026-01-07 to 2031-01-07
  Status: Valid
```

---

## Error: "Certificate Expired"

### Symptoms
```
Error: Certificate has expired
Error: CERT_HAS_EXPIRED
```

### Solution

Certificates are valid for 1 year. Re-pair to generate new ones:

```bash
# Remove expired certificates
healthsync unpair

# Generate new certificates via pairing
healthsync scan
```

On iOS app: Start server → Show QR Code → Scan with Mac

---

## Error: "Certificate Not Yet Valid"

### Symptoms
```
Error: Certificate is not yet valid
Error: CERT_NOT_YET_VALID
```

### Solution

System clock is set to a date before the certificate was created:

```bash
# Check system time
date

# Sync with time server
sudo sntp -sS time.apple.com
```

On iPhone: Settings → General → Date & Time → Set Automatically

---

## Error: "Certificate Signature Invalid"

### Symptoms
```
Error: Certificate signature verification failed
Error: UNABLE_TO_VERIFY_LEAF_SIGNATURE
```

### Solutions

**1. Certificate chain broken**

The CA certificate may be missing or corrupted:
```bash
# Check CA certificate
healthsync cert info --ca

# If missing, re-pair
healthsync unpair
healthsync scan
```

**2. Mismatched CA certificates**

iPhone and Mac have different CA certificates (from different pairing sessions):
```bash
# Complete reset on Mac
healthsync keychain clear

# On iPhone: Delete and reinstall app
# Re-pair from scratch
```

---

## Error: "No Client Certificate"

### Symptoms
```
Error: SSL peer did not present a certificate
Error: NO_CLIENT_CERTIFICATE
```

### Solutions

**1. Certificate not in Keychain**
```bash
# Check if certificate exists
healthsync cert info

# If missing, re-pair
healthsync scan
```

**2. Keychain access denied**
```bash
# Check Keychain permissions
security find-certificate -a -c "healthsync" ~/Library/Keychains/login.keychain-db

# If permission denied, unlock Keychain
security unlock-keychain ~/Library/Keychains/login.keychain-db
```

**3. Wrong Keychain**

Certificate may be in wrong Keychain:
```bash
# List all Keychains
security list-keychains

# Search all Keychains for certificate
security find-certificate -a -c "healthsync"
```

---

## Error: "Certificate Revoked"

### Symptoms
```
Error: Certificate has been revoked
Error: CERT_REVOKED
```

### Solution

The server has revoked the client certificate (usually after unpairing on iPhone):

```bash
# Clear local certificates
healthsync unpair

# Re-pair with new certificates
healthsync scan
```

---

## Error: "Hostname Mismatch"

### Symptoms
```
Error: Hostname/IP does not match certificate
Error: CERT_COMMON_NAME_INVALID
```

### Solutions

**1. IP address changed**

iPhone's IP changed since pairing:
```bash
# Check stored server address
healthsync config show

# Update with new IP
healthsync config set server.host 192.168.1.NEW_IP
```

Or re-pair to update automatically:
```bash
healthsync scan
```

**2. Using wrong address**

Certificate is bound to specific IP/hostname:
```bash
# Use the IP shown in iOS app, not hostname
healthsync fetch --host 192.168.1.100
```

---

## Error: "Untrusted Certificate"

### Symptoms
```
Error: Certificate is not trusted
Error: SELF_SIGNED_CERT_IN_CHAIN
```

### Solution

This is expected for self-signed certificates. The CLI should be configured to trust the specific CA:

```bash
# Verify CA is configured
healthsync cert info --ca

# If CA is missing, re-pair
healthsync unpair
healthsync scan
```

---

## Error: "TLS Handshake Timeout"

### Symptoms
```
Error: TLS handshake timed out
Error: ETIMEDOUT during TLS negotiation
```

### Solutions

**1. Network latency**
```bash
# Test network latency
ping -c 5 192.168.1.100

# If high latency (>100ms), move closer to router
```

**2. Server overloaded**

On iPhone, restart the server:
1. Tap "Stop Sharing"
2. Wait 5 seconds
3. Tap "Start Sharing"

**3. Increase timeout**
```bash
healthsync fetch --timeout 30000  # 30 seconds
```

---

## Error: "Protocol Version Mismatch"

### Symptoms
```
Error: TLS protocol version mismatch
Error: UNSUPPORTED_PROTOCOL
```

### Solution

iOS Health Sync requires TLS 1.3:
```bash
# Check macOS version (must be 15+)
sw_vers

# Check OpenSSL/LibreSSL version
openssl version
```

If using older macOS, upgrade to macOS 15 Sequoia or later.

---

## Keychain Management

### View stored certificates
```bash
# List all healthsync certificates
security find-certificate -a -c "healthsync" -p
```

### Export certificate for debugging
```bash
# Export to file
healthsync cert export --output ~/Desktop/healthsync-cert.pem
```

### Clear all certificates
```bash
# Remove from CLI storage
healthsync keychain clear

# Also remove from system Keychain (if needed)
security delete-certificate -c "healthsync-client"
security delete-certificate -c "healthsync-ca"
```

---

## Certificate Debugging

### Verbose TLS logging
```bash
# Enable debug output
healthsync fetch --debug-tls
```

### Inspect certificate chain
```bash
# Connect and show certificates
openssl s_client -connect 192.168.1.100:8443 \
  -cert client.pem -key client-key.pem \
  -CAfile ca.pem -showcerts
```

### Verify certificate manually
```bash
# Check certificate details
openssl x509 -in cert.pem -text -noout

# Verify against CA
openssl verify -CAfile ca.pem cert.pem
```

---

## Complete Reset Procedure

When all else fails:

### Mac:
```bash
# 1. Clear all stored data
healthsync unpair
healthsync keychain clear
healthsync config reset

# 2. Remove from system Keychain
security delete-certificate -c "healthsync" 2>/dev/null || true

# 3. Verify clean state
healthsync status
```

### iPhone:
1. Open iOS Health Sync app
2. Tap "Settings" → "Reset All Data"
3. Confirm reset
4. Restart app
5. Re-grant HealthKit permissions
6. Start server and scan QR code

---

## Security Notes

- Certificates are stored securely in Keychain (Mac) and Keychain Services (iPhone)
- Private keys never leave the device
- Certificate validity is 1 year by default
- Re-pairing generates completely new certificates

---

## Related Guides

- **[Fix Pairing Issues](./fix-pairing.md)** - Connection problems
- **[Generate Certificates](./generate-certificates.md)** - Manual certificate creation
- **[Security Model](../explanation/security-model.md)** - How mTLS works

---

*Last updated: 2026-01-07*
