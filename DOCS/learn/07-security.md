# Chapter 7: Security - Protecting Health Data

**Secure Storage and Authentication**

---

## Learning Objectives

After this chapter, you will be able to:

- ✅ Understand Keychain storage
- ✅ Implement TLS certificates
- ✅ Build secure pairing
- ✅ Use mTLS authentication
- ✅ Handle sensitive data properly

---

## The Simple Explanation

### Why Security Matters

Health data is **sensitive**:

```
What your health data reveals:
├── Your medical conditions
├── Your lifestyle habits
├── Your location patterns
├── Your sleep schedule
└── Your physiological metrics
```

**If compromised:**
- Insurance discrimination
- Employment issues
- Privacy violation
- Identity theft risk
- Stalking potential

### Our Security Layers

```
┌─────────────────────────────────────┐
│  Application Layer                  │
│  - Rate limiting                    │
│  - Audit logging                    │
│  - Input validation                 │
├─────────────────────────────────────┤
│  Authentication Layer               │
│  - Token-based auth                 │
│  - Token expiration                 │
│  - Revocation support               │
├─────────────────────────────────────┤
│  Transport Layer                    │
│  - TLS 1.3 encryption               │
│  - Certificate pinning              │
│  - mTLS (mutual auth)               │
├─────────────────────────────────────┤
│  Storage Layer                      │
│  - Keychain for secrets             │
│  - SwiftData for metadata           │
│  - Hashed tokens                    │
└─────────────────────────────────────┘
```

---

## Keychain Storage

### What Is Keychain?

**Keychain** is iOS's secure storage enclave:

```
Regular Storage:                    Keychain:
┌─────────────────┐                ┌─────────────────┐
│ app.plist       │                │ 🔒 Keychain     │
│ - UserDefaults  │                │ - Encrypted     │
│ - Files         │                │ - Secure Enclave│
│ - Can be read   │                │ - No direct read│
└─────────────────┘                └─────────────────┘

Access:                           Access:
Any app with file access          Only your app
(when jailbroken)                 (with biometrics)
```

### When to Use Keychain

| Use Keychain For | Don't Use For |
|------------------|---------------|
| API keys | App settings |
| Tokens | Cached data |
| Certificates | User preferences |
| Passwords | Temporary data |
| Secrets | Large files |

### In Our Code: KeychainStore

**File:** `Services/Security/KeychainStore.swift`

```swift
enum KeychainStore {
    private static let service = "com.healthsync"

    static func save(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing
        SecItemDelete(query as CFDictionary)

        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToStore
        }
    }

    static func load(forKey key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.unableToRetrieve
        }

        return data
    }
}
```

**Key attributes:**
- `kSecClassGenericPassword` = Generic password item
- `kSecAttrService` = App identifier
- `kSecAttrAccount` = Key name
- `kSecValueData` = The data to store
- `kSecAttrAccessible` = When accessible

**Accessibility levels:**
- `kSecAttrAccessibleWhenUnlocked` = Default, most secure
- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` = No iCloud backup
- `kSecAttrAccessibleAfterFirstUnlock` = After phone restart
- `kSecAttrAccessibleAlways` = Even when locked (avoid)

---

## TLS Certificates

### What Are TLS Certificates?

**TLS (Transport Layer Security)** certificates prove identity:

```
Server Certificate proves:
├── This server is authentic
├── Not impersonated
└── Communication is encrypted
```

**Like an ID card:**
```
Government ID Card              TLS Certificate
├── Your name                   ├── Server name
├── Photo                       ├── Public key
├── Issue date                  ├── Valid dates
├── Expires                     ├── Expires
└── Government signature        └── CA signature
```

### In Our Code: CertificateService

**File:** `Services/Security/CertificateService.swift`

```swift
enum CertificateService {
    static func loadOrCreateIdentity() throws -> TLSIdentity {
        let keyTag = "com.healthsync.server"

        // Try to load existing
        if let identity = try loadIdentity(keyTag: keyTag) {
            return identity
        }

        // Create new certificate
        return try createIdentity(keyTag: keyTag)
    }

    private static func createIdentity(keyTag: String) throws -> TLSIdentity {
        // Generate private key
        let privateKey = SecKeyCreateRandomKey(
            [
                kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits as String: 256,
                kSecAttrApplicationTag as String: keyTag
            ] as CFDictionary,
            nil
        )!

        // Create certificate
        let certificate = try createCertificate(
            privateKey: privateKey,
            keyTag: keyTag
        )

        // Create identity
        let identity = SecIdentityCreate(
            kSecDefaultKeychain,
            certificate,
            privateKey,
            nil
        )!

        return TLSIdentity(identity: identity, certificate: certificate)
    }
}
```

**Certificate details:**

```swift
private static func createCertificate(privateKey: SecKey, keyTag: String) throws -> SecCertificate {
    // Subject Distinguished Name
    let subject: [String: Any] = [
        kSecOIDX520OrganizationName as String: "HealthSync",
        kSecOIDX520CommonName as String: "HealthSync Server"
    ]

    // X.509 V3 certificate
    let certificateData: [String: Any] = [
        kSecCSRPrivateKeyOID as String: privateKey,
        kSecOIDX520OrganizationName as String: "HealthSync",
        kSecOIDX520CommonName as String: "server.healthsync.local",
        kSecCSRBasicConstraintsPathLen as String: 0,
        kSecCSRIsCA as String: false,
        kSecCSRValidityPeriod as String: 365 * 24 * 60 * 60  // 1 year
    ]

    return try SecCertificateCreateSelfSigned(nil, certificateData as CFDictionary)!
}
```

**Why self-signed?**
- No certificate authority needed
- Perfect for local network
- Client verifies fingerprint directly
- No cost or expiration concerns

---

## Device Pairing

### The Pairing Flow

```
┌──────────────┐                    ┌──────────────┐
│   iPhone     │                    │     Mac      │
│              │                    │              │
│ 1. User taps  │                    │              │
│    "Start"    │                    │              │
│              │                    │              │
│ 2. Generate  │                    │              │
│    QR code   │                    │              │
│    ┌─────┐   │                    │              │
│    │ CODE│   │                    │              │
│    └─────┘   │                    │              │
│              │                    │              │
│              │ 3. User scans QR   │              │
│              │◄───────────────────│              │
│              │                    │              │
│ 4. Receive   │                    │ 5. Send pair │
│    pair req  │                    │    request   │
│              │───────────────────►│              │
│              │                    │              │
│ 5. Validate  │                    │              │
│    code      │                    │              │
│              │                    │              │
│ 6. Generate  │                    │ 7. Receive   │
│    token     │                    │    token     │
│              │───────────────────►│              │
│              │                    │              │
│ 8. Store     │                    │ 9. Store     │
│    device    │                    │    token     │
└──────────────┘                    └──────────────┘
```

### Pairing QR Code

**File:** `Features/QRCodeView.swift`

```swift
struct PairingQRCode {
    let code: String        // 8-character code
    let host: String        // IP address
    let port: Int           // Server port
    let fingerprint: String // Certificate fingerprint
    let expiresAt: Date     // Expiration time
}
```

**QR code format:**
```
healthsync://pair?code=ABC12345&host=192.168.1.100&port=8443&fp=aa:bb:cc:dd
```

### PairingService

**File:** `Services/Security/PairingService.swift`

```swift
actor PairingService {
    private let modelContainer: ModelContainer

    func generateQRCode(host: String, port: Int, fingerprint: String) async -> PairingQRCode {
        let code = generateSecureCode()
        let expiresAt = Date().addingTimeInterval(5 * 60) // 5 minutes

        return PairingQRCode(
            code: code,
            host: host,
            port: port,
            fingerprint: fingerprint,
            expiresAt: expiresAt
        )
    }

    private func generateSecureCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // No I, O, 0, 1
        return String((0..<8).map { _ in
            characters.randomElement()!
        })
    }
}
```

**Secure code generation:**
- 8 characters
- 62^8 combinations (218 trillion)
- Excludes ambiguous chars (I, O, 0, 1)
- 5-minute expiration

### Handling Pair Request

```swift
func handlePairRequest(_ request: PairRequest) async throws -> PairResponse {
    // Validate code
    guard let qrCode = currentQRCode,
          qrCode.code == request.code else {
        throw PairingError.invalidCode
    }

    // Check expiration
    guard Date() < qrCode.expiresAt else {
        throw PairingError.codeExpired
    }

    // Check rate limiting
    guard !isRateLimited(for: request.clientName) else {
        throw PairingError.tooManyAttempts
    }

    // Generate token
    let token = generateToken()
    let hashedToken = SHA256.hash(data: Data(token.utf8))

    // Store paired device
    let context = modelContainer.mainContext
    let device = PairedDevice(
        name: anonymizeDeviceName(request.clientName),
        tokenHash: hashedToken.compactMap { String(format: "%02x", $0) }.joined(),
        createdAt: Date(),
        expiresAt: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days
        lastSeenAt: nil,
        isActive: true
    )
    context.insert(device)
    try context.save()

    return PairResponse(token: token, expiresAt: device.expiresAt)
}
```

---

## mTLS Authentication

### What Is mTLS?

**mTLS (mutual TLS)** means both sides prove identity:

```
Regular TLS:                      mTLS:
Client ──► Server                 Client ──► Server
  Verifies                          Verifies
  Server only                      Server ✓
                                   Client ✓
```

**Why mTLS?**
- Server proves it's legitimate
- Client proves it's authorized
- Prevents man-in-the-middle
- No password transmission

### Server Certificate

Our server presents its certificate:

```swift
// File: Services/Network/NetworkServer.swift:54-61
let tlsOptions = NWProtocolTLS.Options()
sec_protocol_options_set_min_tls_protocol_version(
    tlsOptions.securityProtocolOptions,
    .TLSv13
)

if let secIdentity = sec_identity_create(identity.identity) {
    sec_protocol_options_set_local_identity(
        tlsOptions.securityProtocolOptions,
        secIdentity
    )
}
```

### Client Certificate Pinning

**File:** `macOS/HealthSyncCLI/Sources/HealthSyncCLI/main.swift`

```swift
func validateCertificate(fingerprint: String) -> Bool {
    guard let certificate = trust.certificate(at: 0) else {
        return false
    }

    let certFingerprint = certificate.fingerprint
    return certFingerprint == fingerprint
}
```

**Fingerprint comparison:**
```
Server's certificate fingerprint (from QR code)
    ↓
Client calculates received certificate's fingerprint
    ↓
Constant-time comparison (prevents timing attacks)
    ↓
Only if match: proceed
```

---

## Token-Based Authentication

### Token Format

```swift
struct AuthToken {
    let value: String           // 256-bit random
    let createdAt: Date
    let expiresAt: Date
}
```

**Token storage:**
```
Raw token (never stored)
    ↓
SHA256 hash
    ↓
Store in SwiftData (PairedDevice.tokenHash)
```

### Validating Tokens

```swift
func validateToken(_ token: String) async -> Bool {
    let hashedToken = hashToken(token)

    let context = modelContainer.mainContext
    let descriptor = FetchDescriptor<PairedDevice>(
        predicate: #Predicate { $0.tokenHash == hashedToken && $0.isActive == true }
    )

    guard let device = try? context.fetch(descriptor).first else {
        return false
    }

    // Check expiration
    guard Date() < device.expiresAt else {
        device.isActive = false
        try? context.save()
        return false
    }

    // Update last seen
    device.lastSeenAt = Date()
    try? context.save()

    return true
}
```

---

## Rate Limiting

**File:** `Services/Network/NetworkServer.swift:337-347`

```swift
private func isRateLimited(token: String) -> Bool {
    let now = Date()
    var entries = requestLog[token, default: []].filter {
        now.timeIntervalSince($0) < rateWindow  // 60 seconds
    }

    if entries.count >= rateLimit {  // 60 requests
        requestLog[token] = entries
        return true
    }

    entries.append(now)
    requestLog[token] = entries
    return false
}
```

**Rate limit:**
- 60 requests per minute
- Per token
- Sliding window
- Automatic cleanup

---

## Security Best Practices

### 1. Never Log Secrets

```swift
// ❌ WRONG
AppLoggers.security.info("Token: \(token)")

// ✅ RIGHT
AppLoggers.security.info("Token validated")
```

### 2. Constant-Time Comparison

```swift
// ❌ WRONG: Early exit on mismatch
func compare(_ a: String, _ b: String) -> Bool {
    return a == b  // Timing varies by position of mismatch
}

// ✅ RIGHT: Constant time
func constantTimeCompare(_ a: String, _ b: String) -> Bool {
    return safeCompare(a, b)  // Always takes same time
}
```

### 3. Hash Before Storing

```swift
// ❌ WRONG: Store raw token
device.token = rawToken

// ✅ RIGHT: Store hash
device.tokenHash = SHA256.hash(rawToken)
```

### 4. Anonymize PII

```swift
// ❌ WRONG
let deviceName = "Marcus's iPhone"

// ✅ RIGHT
let deviceName = anonymize("Marcus's iPhone")
// Returns: "Client-A3F2"
```

---

## Exercises

### 🟢 Beginner: Generate Secure Code

**Task:** Implement secure code generator:

```swift
func generateSecureCode(length: Int = 8) -> String {
    // Use only: A-Z, 2-9 (exclude I, O, 0, 1)
    // Your code here
}
```

---

### 🟡 Intermediate: Hash and Verify Token

**Task:** Implement token hashing and verification:

```swift
struct TokenManager {
    func hash(_ token: String) -> String {
        // Use SHA256
    }

    func verify(token: String, hash: String) -> Bool {
        // Constant-time comparison
    }
}
```

---

### 🔴 Advanced: Implement Certificate Validation

**Task:** Write certificate fingerprint validation:

```swift
func validateCertificate(
    _ certificate: SecCertificate,
    expectedFingerprint: String
) -> Bool {
    // Calculate fingerprint
    // Compare with expected
    // Return result
}
```

---

## Common Pitfalls

### Pitfall 1: Storing raw secrets

```swift
// WRONG
UserDefaults.standard.set(token, forKey: "token")

// RIGHT
try KeychainStore.save(token.data, forKey: "token")
```

### Pitfall 2: Timing attacks

```swift
// WRONG: Early exit
func validate(code: String) -> Bool {
    guard code.count == 8 else { return false }
    return code == storedCode  // Timing varies
}

// RIGHT: Constant time
func validate(code: String) -> Bool {
    return constantTimeCompare(code, storedCode)
}
```

### Pitfall 3: No rate limiting

```swift
// WRONG: No limit
while true {
    tryPair(guessCode())
}

// RIGHT: Rate limit
if isRateLocked(ip) {
    return "Too many attempts"
}
```

---

## Key Takeaways

### ✅ Security Patterns

| Pattern | Purpose |
|---------|---------|
| **Keychain** | Store secrets |
| **TLS 1.3** | Encrypt transport |
| **mTLS** | Mutual authentication |
| **Token hash** | Never store raw tokens |
| **Rate limit** | Prevent brute force |
| **Certificate pinning** | Prevent MITM |

---

## Coming Next

In **Chapter 8: Networking - Device Communication**, you'll learn:

- Building HTTP servers
- Request/response handling
- Bonjour discovery
- Error handling

---

**Next Chapter:** [Networking - Device Communication](08-networking.md) →
