# Generate Certificates: Create mTLS Certificates

**Manually create and manage TLS certificates for device pairing**

---

**Time:** 20 minutes
**Difficulty:** Intermediate
**Prerequisites:**
- [ ] Understanding of TLS/mTLS concepts
- [ ] iOS app running
- [ ] macOS CLI available
- [ ] OpenSSL installed (optional, for inspection)

---

## Goal

Understand how certificates are generated and exchanged during pairing, and how to manually manage them if needed.

---

## Background

iOS Health Sync uses **mutual TLS (mTLS)** for secure communication:

1. **iOS device** generates a self-signed certificate
2. **Mac CLI** generates its own certificate
3. **Both sides** exchange and trust each other's certificates
4. **All communication** is encrypted and mutually authenticated

---

## Steps

### Step 1: Understand Certificate Generation (iOS)

The iOS app automatically generates certificates using `CertificateService`:

```swift
// In CertificateService.swift
func generateSelfSignedCertificate() throws -> (certificate: SecCertificate, privateKey: SecKey) {
    // 1. Generate P-256 key pair
    let privateKey = try generatePrivateKey()
    let publicKey = SecKeyCopyPublicKey(privateKey)!

    // 2. Create certificate using DER encoding
    let certificateData = try createCertificate(
        publicKey: publicKey,
        privateKey: privateKey,
        subject: "iOS Health Sync Device"
    )

    // 3. Return certificate and private key
    return (certificate, privateKey)
}
```

**Key details:**
- Algorithm: P-256 (secp256r1) elliptic curve
- Validity: 365 days
- Key usage: Digital signature, key encipherment

---

### Step 2: Inspect Generated Certificate

**On iOS (via logs):**

Enable debug logging to see certificate details:

```bash
log stream --predicate 'subsystem == "org.mvneves.healthsync"' --level debug
```

**Using OpenSSL (on exported certificate):**

```bash
# If you export the certificate to a file
openssl x509 -in certificate.pem -text -noout

# Output shows:
# - Subject: CN=iOS Health Sync Device
# - Validity: 365 days
# - Public Key Algorithm: id-ecPublicKey
# - Signature Algorithm: ecdsa-with-SHA256
```

---

### Step 3: View Certificate Fingerprint

**On iOS app:**
1. Open iOS Health Sync
2. Go to Settings (gear icon)
3. View "Certificate Fingerprint"

**On CLI:**
```bash
healthsync status
# Shows: Fingerprint: SHA256:abc123...
```

**Important:** Both fingerprints must match for secure pairing.

---

### Step 4: Regenerate Certificates (iOS)

If you need to regenerate certificates:

1. **In iOS app:**
   - Go to Settings
   - Tap "Reset Security"
   - Confirm the action

2. **Effect:**
   - All existing pairings are invalidated
   - New certificate is generated
   - Devices must re-pair

**Code equivalent:**
```swift
// Clear existing certificates
try KeychainStore.shared.delete(key: "deviceCertificate")
try KeychainStore.shared.delete(key: "devicePrivateKey")

// Generate new certificate
let (cert, key) = try certificateService.generateSelfSignedCertificate()

// Store new certificate
try KeychainStore.shared.store(cert, forKey: "deviceCertificate")
try KeychainStore.shared.store(key, forKey: "devicePrivateKey")
```

---

### Step 5: Regenerate Certificates (CLI)

```bash
# Remove existing pairing
healthsync unpair

# Clear certificate store
healthsync reset --certificates

# Re-pair to generate new certificates
healthsync scan
```

---

### Step 6: Certificate Storage Locations

**iOS:**
- Keychain (protected by Secure Enclave)
- Access group: `$(AppIdentifierPrefix)org.mvneves.healthsync`

**macOS CLI:**
- User Keychain: `~/Library/Keychains/login.keychain-db`
- Service name: `healthsync-certificate`

---

## Verification

**Verify certificate chain:**

```bash
# Test TLS connection
openssl s_client -connect localhost:8080 -showcerts

# Should show:
# - Server certificate
# - Certificate chain (self-signed, so only one cert)
# - Verify return code: 18 (self signed certificate) - expected
```

**Verify mutual authentication:**

```bash
# With client certificate
openssl s_client -connect localhost:8080 \
  -cert client.pem \
  -key client-key.pem \
  -showcerts
```

---

## Common Issues

### Issue: "Certificate has expired"

**Cause:** Certificate older than 365 days.

**Solution:**
1. Regenerate certificate on iOS (Settings > Reset Security)
2. Re-pair devices

### Issue: "Certificate verification failed"

**Cause:** Certificate mismatch between devices.

**Solution:**
1. Verify fingerprints match on both devices
2. If not, unpair and re-pair

### Issue: "Keychain access denied"

**Cause:** App not authorized to access Keychain.

**Solution (iOS):**
- Check entitlements include keychain-access-groups
- Reinstall app to reset Keychain permissions

**Solution (macOS):**
```bash
# Unlock keychain
security unlock-keychain ~/Library/Keychains/login.keychain-db
```

---

## Advanced: Manual Certificate Creation

**For testing/debugging only:**

```bash
# Generate private key
openssl ecparam -genkey -name prime256v1 -out private.pem

# Generate self-signed certificate
openssl req -new -x509 -key private.pem -out certificate.pem -days 365 \
  -subj "/CN=Test Certificate"

# Convert to DER format (iOS compatible)
openssl x509 -in certificate.pem -outform DER -out certificate.der

# View certificate
openssl x509 -in certificate.pem -text -noout
```

---

## Security Considerations

**Best practices:**
- Never export or share private keys
- Rotate certificates annually (automatic with 365-day validity)
- Use Secure Enclave on iOS when available
- Log certificate operations via AuditService

**What's stored where:**

| Item | Location | Protection |
|------|----------|------------|
| iOS Private Key | Secure Enclave | Hardware |
| iOS Certificate | Keychain | Device passcode |
| Mac Private Key | Keychain | Login password |
| Mac Certificate | Keychain | Login password |
| Peer Certificates | Keychain | App-specific |

---

## See Also

- [Security Model](../explanation/security-model.md) - How security works
- [Pair Devices](./pair-devices.md) - Standard pairing flow
- [Troubleshooting Pairing](./fix-pairing.md) - Pairing issues

---

**Last Updated:** 2026-01-07
