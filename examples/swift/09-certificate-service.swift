#!/usr/bin/env swift -parse-as-library
// Example 9: Real CertificateService from iOS Health Sync App
//
// ⚠️ IMPORTANT: This example shows PATTERNS from the real app code
// but cannot compile standalone because it depends on Apple's Security framework.
//
// This file demonstrates:
// - Keychain-based certificate storage
// - Self-signed TLS certificate generation
// - ECDSA private key creation (P-256 curve)
// - Certificate fingerprint calculation (SHA256)
// - Thread-safe identity creation
// - Proper error handling
//
// For WORKING examples, see examples 01-05 which are self-contained.
//
// To see the ACTUAL working code, open:
// iOS Health Sync App/iOS Health Sync App/Services/Security/CertificateService.swift

import Foundation

// MARK: - 1. TLS Identity Type

/// Represents a TLS identity (certificate + private key)
/// From: iOS Health Sync App/Services/Security/CertificateService.swift
struct TLSIdentity {
    let identity: SecIdentity
    let certificateData: Data
    let fingerprint: String
}

// MARK: - 2. Certificate Service

/// Manages TLS certificate generation and storage
///
/// Real-world patterns:
/// - Keychain storage (encrypted at rest)
/// - Self-signed certificates (no CA needed)
/// - ECDSA P-256 keys (modern, secure)
/// - Thread-safe creation (DispatchQueue)
/// - Lazy creation (only when needed)
struct CertificateService {

    // MARK: - Keychain Configuration

    /// Unique identifier for our TLS private key
    private static let keyTag = "org.mvneves.healthsync.tlskey"

    /// Human-readable label for certificate
    private static let certLabel = "HealthSync Local TLS"

    /// Serialize identity creation to prevent race conditions
    /// During app startup, multiple threads might try to create identity
    private static let identityQueue = DispatchQueue(
        label: "org.mvneves.healthsync.tlsidentity"
    )

    // MARK: - 3. Load or Create Identity

    /// Load existing identity or create new one
    ///
    /// Thread-safety: Uses DispatchQueue.sync to serialize access
    /// Pattern: Check if exists → return it, otherwise create new
    static func loadOrCreateIdentity() throws -> TLSIdentity {
        // Serialize access to prevent race conditions
        return try identityQueue.sync {
            // Try to load existing
            if let existing = try? loadIdentity() {
                AppLoggers.security.info("Loaded existing TLS identity")
                return existing
            }

            // Need to create new
            AppLoggers.security.info("Creating new TLS identity")

            // Step 1: Generate private key
            let privateKey = try createPrivateKey(persist: true)

            // Step 2: Extract public key
            guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
                throw CertificateError.keyGenerationFailed
            }

            // Step 3: Build self-signed certificate
            let certData = try buildSelfSignedCertificate(
                privateKey: privateKey,
                publicKey: publicKey
            )

            // Step 4: Store certificate in Keychain
            try storeCertificate(certData)

            // Step 5: Create SecIdentity from certificate + key
            guard let certificate = SecCertificateCreateWithData(
                nil,
                certData as CFData
            ) else {
                throw CertificateError.notFound
            }

            guard let identity = SecIdentityCreate(
                nil,
                certificate,
                privateKey
            ) else {
                throw CertificateError.identityFailed
            }

            // Step 6: Calculate fingerprint (for verification)
            let fingerprint = sha256Fingerprint(certData)

            AppLoggers.security.info("TLS identity created successfully")

            return TLSIdentity(
                identity: identity,
                certificateData: certData,
                fingerprint: fingerprint
            )
        }
    }

    // MARK: - 4. Ephemeral Identity (for testing)

    /// Create temporary identity not stored in Keychain
    ///
    /// Use case: Testing, ephemeral connections
    static func createEphemeralIdentity() throws -> TLSIdentity {
        // Generate private key (not persisted)
        let privateKey = try createPrivateKey(persist: false)

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw CertificateError.keyGenerationFailed
        }

        // Build certificate
        let certData = try buildSelfSignedCertificate(
            privateKey: privateKey,
            publicKey: publicKey
        )

        // Create identity (not stored)
        guard let certificate = SecCertificateCreateWithData(
            nil,
            certData as CFData
        ) else {
            throw CertificateError.notFound
        }

        guard let identity = SecIdentityCreate(nil, certificate, privateKey) else {
            throw CertificateError.identityFailed
        }

        let fingerprint = sha256Fingerprint(certData)

        return TLSIdentity(
            identity: identity,
            certificateData: certData,
            fingerprint: fingerprint
        )
    }

    // MARK: - 5. Load Existing Identity

    /// Load identity from Keychain
    ///
    /// Returns: TLSIdentity if found
    /// Throws: CertificateError.notFound if not in Keychain
    private static func loadIdentity() throws -> TLSIdentity {
        // Load certificate from Keychain
        let certQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: certLabel,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var certItem: CFTypeRef?
        let certStatus = SecItemCopyMatching(certQuery as CFDictionary, &certItem)

        guard certStatus == errSecSuccess,
              let certData = certItem as? Data else {
            throw CertificateError.notFound
        }

        guard let certificate = SecCertificateCreateWithData(
            nil,
            certData as CFData
        ) else {
            throw CertificateError.notFound
        }

        // Load private key from Keychain
        let tagData = keyTag.data(using: .utf8) ?? Data()
        let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrApplicationTag as String: tagData,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var keyItem: CFTypeRef?
        let keyStatus = SecItemCopyMatching(keyQuery as CFDictionary, &keyItem)

        guard keyStatus == errSecSuccess,
              let privateKey = keyItem else {
            throw CertificateError.notFound
        }

        // Create identity from certificate + key
        guard let identity = SecIdentityCreate(nil, certificate, privateKey) else {
            throw CertificateError.identityFailed
        }

        let fingerprint = sha256Fingerprint(certData)

        return TLSIdentity(
            identity: identity,
            certificateData: certData,
            fingerprint: fingerprint
        )
    }

    // MARK: - 6. Private Key Creation

    /// Create ECDSA private key
    ///
    /// Algorithm: Elliptic Curve Digital Signature Algorithm
    /// Curve: P-256 (NIST standard, 256-bit)
    ///
    /// Security: 128-bit security level
    /// Performance: Faster than RSA, smaller keys
    private static func createPrivateKey(persist: Bool) throws -> SecKey {
        // Key parameters
        let tagData = keyTag.data(using: .utf8) ?? Data()

        var error: Unmanaged<CFError>?

        // Key attributes
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,  // P-256 curve
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: persist,
                kSecAttrApplicationTag as String: tagData
            ]
        ]

        // Generate key
        guard let privateKey = SecKeyCreateRandomKey(
            attributes as CFDictionary,
            &error
        ) else {
            throw CertificateError.keyGenerationFailed
        }

        return privateKey
    }

    // MARK: - 7. Self-Signed Certificate

    /// Build self-signed X.509 certificate
    ///
    /// This is a simplified version - real implementation builds
    /// proper DER-encoded certificate with:
    /// - Version: X.509 v3
    /// - Serial number: Random
    /// - Subject: CN=<device name>
    /// - Issuer: Same as subject (self-signed)
    /// - Validity: 1 year
    /// - Public key: From generated key pair
    /// - Extensions: Basic constraints, key usage
    private static func buildSelfSignedCertificate(
        privateKey: SecKey,
        publicKey: SecKey
    ) throws -> Data {
        // In real app: Use CryptoKit and manual DER encoding
        // This is complex - requires building ASN.1 structures

        // Simplified: Return mock certificate data
        return Data()
    }

    // MARK: - 8. Store Certificate

    /// Store certificate in Keychain
    private static func storeCertificate(_ certData: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: certLabel,
            kSecValueData as String: certData,
            kSecAttrIsPermanent as String: true
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Already exists - update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassCertificate,
                kSecAttrLabel as String: certLabel
            ]

            let updateStatus = SecItemUpdate(
                updateQuery as CFDictionary,
                [kSecValueData as String: certData] as CFDictionary
            )

            guard updateStatus == errSecSuccess else {
                throw CertificateError.storageFailed
            }
        } else if status != errSecSuccess {
            throw CertificateError.storageFailed
        }
    }

    // MARK: - 9. Certificate Fingerprint

    /// Calculate SHA256 fingerprint of certificate
    ///
    /// Use case: Verify certificate during pairing
    /// CLI shows fingerprint to user for manual verification
    static func sha256Fingerprint(_ data: Data) -> String {
        // In real app: Use CryptoKit.SHA256
        // hash = SHA256.hash(data: certificateData)

        // Simplified: Return mock fingerprint
        return "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD"
    }
}

// MARK: - 10. Supporting Types

enum CertificateError: LocalizedError {
    case notFound
    case keyGenerationFailed
    case identityFailed
    case storageFailed

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Certificate not found in Keychain"
        case .keyGenerationFailed:
            return "Failed to generate private key"
        case .identityFailed:
            return "Failed to create SecIdentity"
        case .storageFailed:
            return "Failed to store certificate in Keychain"
        }
    }
}

enum AppLoggers {
    static let security = OSLog(subsystem: "org.mvneves", category: "Security")
}

struct OSLog {
    let subsystem: String
    let category: String
    func info(_ message: String) {}
}

// Mock types for compilation
typealias SecIdentity = NSObject
typealias SecKey = NSObject
typealias SecCertificate = NSObject

func SecItemCopyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>) -> OSStatus { errSecSuccess }
func SecItemAdd(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>) -> OSStatus { errSecSuccess }
func SecItemUpdate(_ query: CFDictionary, _ attributes: CFDictionary) -> OSStatus { errSecSuccess }
func SecKeyCreateRandomKey(_ attributes: CFDictionary, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>) -> SecKey? { NSObject() }
func SecKeyCopyPublicKey(_ key: SecKey) -> SecKey? { NSObject() }
func SecCertificateCreateWithData(_ allocator: CFAllocator?, _ data: CFData) -> SecCertificate? { NSObject() }
func SecIdentityCreate(_ allocator: CFAllocator?, _ certificate: SecCertificate, _ privateKey: SecKey) -> SecIdentity? { NSObject() }

let kSecClass: String = "class"
let kSecClassCertificate: String = "certificate"
let kSecClassKey: String = "key"
let kSecAttrLabel: String = "label"
let kSecAttrKeyType: String = "keyType"
let kSecAttrKeyTypeECSECPrimeRandom: String = "ecdsa"
let kSecAttrKeySizeInBits: String = "size"
let kSecAttrTokenID: String = "tokenID"
let kSecAttrTokenIDSecureEnclave: String = "secureEnclave"
let kSecPrivateKeyAttrs: String = "privateAttrs"
let kSecAttrIsPermanent: String = "permanent"
let kSecAttrApplicationTag: String = "appTag"
let kSecValueData: String = "value"
let kSecReturnData: String = "returnData"
let kSecReturnRef: String = "returnRef"
let kSecMatchLimit: String = "matchLimit"
let kSecMatchLimitOne: String = "one"
typealias OSStatus = Int32
let errSecSuccess: OSStatus = 0
let errSecDuplicateItem: OSStatus = -25299

// MARK: - 11. Main Execution Example

@main
struct CertificateServiceExample {
    static func main() async {
        print("=== Real CertificateService Example ===")
        print("")
        print("This example shows the ACTUAL CertificateService from iOS Health Sync.")
        print("")
        print("Key Concepts:")
        print("  • TLS certificates for secure communication")
        print("  • Self-signed certificates (no CA needed)")
        print("  • ECDSA P-256 keys (modern, secure)")
        print("  • Keychain storage (encrypted at rest)")
        print("")
        print("Security Features:")
        print("  • Private keys stored in Secure Enclave (if available)")
        print("  • Certificate fingerprints for manual verification")
        print("  • Thread-safe identity creation")
        print("  • Automatic key generation")
        print("")
        print("Certificate Details:")
        print("  • Algorithm: ECDSA (Elliptic Curve)")
        print("  • Curve: P-256 (NIST standard)")
        print("  • Security level: 128-bit")
        print("  • Key size: 256 bits (32 bytes)")
        print("  • Signature: SHA256 with ECDSA")
        print("")
        print("Why Self-Signed?")
        print("  • No Certificate Authority needed")
        print("  • Perfect for local network apps")
        print("  • User manually verifies fingerprint")
        print("  • Zero infrastructure cost")
        print("")
        print("✅ Example Complete!")
    }
}

// Note: This is a simplified version of the real code for clarity.
// The actual certificate DER encoding is complex and requires
// careful ASN.1 structure building.
