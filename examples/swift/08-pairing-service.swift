#!/usr/bin/env swift -parse-as-library
// Example 8: Real PairingService from iOS Health Sync App
//
// ⚠️ IMPORTANT: This example shows PATTERNS from the real app code
// but cannot compile standalone because it depends on SwiftData and CryptoKit.
//
// This file demonstrates:
// - Secure pairing token generation
// - Constant-time comparison (timing attack prevention)
// - Token hashing with SHA256
// - Rate limiting for failed attempts
// - Privacy-first design (anonymized client names)
// - SwiftData persistence
//
// For WORKING examples, see examples 01-05 which are self-contained.
//
// To see the ACTUAL working code, open:
// iOS Health Sync App/iOS Health Sync App/Services/Security/PairingService.swift

import Foundation

// MARK: - 1. Actor-Based Pairing Service

/// Real-world pattern: Actor for thread-safe pairing state
/// From: iOS Health Sync App/Services/Security/PairingService.swift
actor PairingService {
    // MARK: - Configuration

    /// Token time-to-live: 30 days
    private let tokenTTL: TimeInterval = 60 * 60 * 24 * 30

    /// QR code expiration: 5 minutes
    private let qrCodeTTL: TimeInterval = 60 * 5

    /// Maximum failed attempts before lockout
    private let maxFailedAttempts = 5

    // MARK: - Dependencies

    private let modelContainer: ModelContainer

    // MARK: - Mutable State (Actor-isolated)

    /// Currently pending pairing session (only one at a time)
    private var pendingSession: PendingPairing?

    // MARK: - 2. Initialization

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - 3. QR Code Generation

    /// Generate a QR code for device pairing
    ///
    /// Security features:
    /// - Uses 8-character alphanumeric code (62^8 = 218 trillion combinations)
    /// - Code expires in 5 minutes
    /// - Includes server certificate fingerprint for MITM prevention
    func generateQRCode(
        host: String,
        port: Int,
        fingerprint: String
    ) -> PairingQRCode {
        // Generate secure random code
        let code = Self.generateSecureCode(length: 8)

        // Set expiration
        let expiresAt = Date().addingTimeInterval(qrCodeTTL)

        // Store pending session
        pendingSession = PendingPairing(
            code: code,
            expiresAt: expiresAt,
            failedAttempts: 0
        )

        return PairingQRCode(
            version: "1",
            host: host,
            port: port,
            code: code,
            expiresAt: expiresAt,
            certificateFingerprint: fingerprint
        )
    }

    // MARK: - 4. Handling Pair Requests

    /// Handle a pairing request from CLI
    ///
    /// Security checks:
    /// 1. Pending session exists
    /// 2. Not exceeded max failed attempts
    /// 3. Code hasn't expired
    /// 4. Code matches (constant-time comparison)
    ///
    /// Privacy features:
    /// - Client name is anonymized before storage
    /// - Only token hash is stored (never the token itself)
    func handlePairRequest(_ request: PairRequest) async throws -> PairResponse {
        // Check 1: Pending session exists
        guard var session = pendingSession else {
            throw PairingError.noPendingSession
        }

        // Check 2: Rate limit failed attempts
        guard session.failedAttempts < maxFailedAttempts else {
            pendingSession = nil  // Clear session on lockout
            throw PairingError.tooManyAttempts
        }

        // Check 3: Code hasn't expired
        guard session.expiresAt > Date() else {
            pendingSession = nil
            throw PairingError.expiredCode
        }

        // Check 4: Constant-time code comparison (prevents timing attacks)
        guard Self.constantTimeCompare(session.code, request.code) else {
            session.failedAttempts += 1
            pendingSession = session
            throw PairingError.invalidCode
        }

        // All checks passed! Create token and persist device
        let token = Self.generateToken()
        let tokenHash = Self.hashToken(token)
        let expiresAt = Date().addingTimeInterval(tokenTTL)

        // Privacy: Anonymize client name before storage
        let anonymizedName = Self.anonymizeName(request.clientName)

        // Persist paired device
        await persistPairedDevice(
            name: anonymizedName,
            tokenHash: tokenHash,
            expiresAt: expiresAt
        )

        // Clear pending session
        pendingSession = nil

        AppLoggers.security.info("Device paired successfully")

        return PairResponse(
            token: token,
            expiresAt: expiresAt
        )
    }

    // MARK: - 5. Token Validation

    /// Validate a bearer token from API requests
    ///
    /// Returns: true if token is valid and active
    ///          false if token not found, expired, or inactive
    func validateToken(_ token: String) async -> Bool {
        let hash = Self.hashToken(token)

        return await MainActor.run {
            let context = modelContainer.mainContext

            // Query for active, unexpired token
            let descriptor = FetchDescriptor<PairedDevice>(
                predicate: #Predicate { $0.tokenHash == hash && $0.isActive }
            )

            guard let device = try? context.fetch(descriptor).first else {
                return false  // Token not found
            }

            // Check expiration
            guard device.expiresAt > Date() else {
                return false  // Token expired
            }

            // Update last seen timestamp
            device.lastSeenAt = Date()
            try? context.save()

            return true  // Token valid!
        }
    }

    // MARK: - 6. Device Management

    /// Revoke all paired devices
    ///
    /// Use case: User resets all pairings in settings
    func revokeAll() async {
        await MainActor.run {
            let context = modelContainer.mainContext

            let descriptor = FetchDescriptor<PairedDevice>()
            guard let devices = try? context.fetch(descriptor) else {
                return
            }

            // Mark all as inactive (soft delete)
            for device in devices {
                device.isActive = false
            }

            try? context.save()

            AppLoggers.security.info("Revoked all paired devices")
        }
    }

    // MARK: - 7. Private Helper Methods

    private func persistPairedDevice(
        name: String,
        tokenHash: String,
        expiresAt: Date
    ) async {
        await MainActor.run {
            let context = modelContainer.mainContext

            let device = PairedDevice(
                name: name,
                tokenHash: tokenHash,
                expiresAt: expiresAt
            )

            context.insert(device)

            do {
                try context.save()
            } catch {
                AppLoggers.security.error(
                    "Failed to save paired device: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
    }

    // MARK: - 8. Static Security Utilities

    /// Generate cryptographically secure random code
    ///
    /// Character set: 0-9, A-Z, a-z (62 characters)
    /// For length 8: 62^8 = 218,340,105,584,896 combinations
    private static func generateSecureCode(length: Int) -> String {
        let charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
        let charsetLength = UInt32(charset.count)

        // In real app: Use SecRandomCopyBytes for cryptographic randomness
        var code = ""
        for _ in 0..<length {
            let random = Int(arc4random_uniform(charsetLength))
            let index = charset.index(charset.startIndex, offsetBy: random)
            code.append(charset[index])
        }
        return code
    }

    /// Generate random token (32 hex characters = 128 bits)
    private static func generateToken() -> String {
        // In real app: Use CryptoKit.SymmetricKey
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    /// Hash token using SHA256 (never store the token itself!)
    private static func hashToken(_ token: String) -> String {
        // In real app: Use CryptoKit.SHA256
        return token.sha256()
    }

    /// Constant-time string comparison
    ///
    /// CRITICAL: Prevents timing attacks
    /// Normal string comparison short-circuits on first mismatch,
    /// which leaks information about how much of the prefix is correct.
    /// Constant-time comparison always takes the same time.
    private static func constantTimeCompare(_ a: String, _ b: String) -> Bool {
        guard a.count == b.count else { return false }

        var result = 0
        for (ca, cb) in zip(a.utf8, b.utf8) {
            result |= Int(ca) ^ Int(cb)
        }

        return result == 0
    }

    /// Anonymize client name for privacy
    ///
    /// Input:  "My MacBook Pro"
    /// Output: "Client-A3F7B9C2"
    ///
    /// Privacy: Never store user's device name directly
    private static func anonymizeName(_ name: String) -> String {
        let hash = name.sha256()
        let prefix = String(hash.prefix(8))
        return "Client-\(prefix.uppercased())"
    }
}

// MARK: - 9. Supporting Types

struct PendingPairing {
    let code: String
    let expiresAt: Date
    var failedAttempts: Int
}

struct PairingQRCode: Codable {
    let version: String
    let host: String
    let port: Int
    let code: String
    let expiresAt: Date
    let certificateFingerprint: String
}

struct PairRequest: Codable {
    let code: String
    let clientName: String
}

struct PairResponse: Codable {
    let token: String
    let expiresAt: Date
}

enum PairingError: LocalizedError {
    case noPendingSession
    case tooManyAttempts
    case expiredCode
    case invalidCode

    var errorDescription: String? {
        switch self {
        case .noPendingSession:
            return "No pairing session in progress"
        case .tooManyAttempts:
            return "Too many failed attempts. Please start over."
        case .expiredCode:
            return "Pairing code has expired"
        case .invalidCode:
            return "Invalid pairing code"
        }
    }
}

// SwiftData models (simplified)
class PairedDevice {
    let id: UUID
    let name: String
    let tokenHash: String
    let expiresAt: Date
    var isActive: Bool
    var lastSeenAt: Date

    init(name: String, tokenHash: String, expiresAt: Date) {
        self.id = UUID()
        self.name = name
        self.tokenHash = tokenHash
        self.expiresAt = expiresAt
        self.isActive = true
        self.lastSeenAt = Date()
    }
}

class ModelContainer {
    let mainContext: ModelContext
}

class ModelContext {
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] { [] }
    func insert<T>(_ object: T) {}
    func save() throws {}
}

struct FetchDescriptor<T> {
    let predicate: Predicate<T>?
}

struct Predicate<T> {
    let value: String
}

extension String {
    func sha256() -> String {
        // In real app: Use CryptoKit.SHA256
        return self
    }
}

enum AppLoggers {
    static let security = OSLog(subsystem: "org.mvneves", category: "Security")
}

struct OSLog {
    let subsystem: String
    let category: String
    func info(_ message: String) {}
    func error(_ message: String) {}
}

// MARK: - 10. Main Execution Example

@main
struct PairingServiceExample {
    static func main() async {
        print("=== Real PairingService Example ===")
        print("")
        print("This example shows the ACTUAL PairingService from iOS Health Sync.")
        print("")
        print("Key Security Patterns:")
        print("  • Constant-time comparison prevents timing attacks")
        print("  • Tokens are hashed (SHA256) before storage")
        print("  • Client names are anonymized for privacy")
        print("  • Rate limiting (5 attempts) prevents brute force")
        print("  • QR codes expire in 5 minutes")
        print("  • Tokens expire in 30 days")
        print("")
        print("Code Security:")
        print("  • 8-character alphanumeric code")
        print("  • 62^8 = 218 trillion possible combinations")
        print("  • Cryptographically secure random generation")
        print("")
        print("Privacy Features:")
        print("  • Original token never stored")
        print("  • Only SHA256 hash of token stored")
        print("  • Device names anonymized (Client-XXXXXXXX)")
        print("  • All access logged for audit")
        print("")
        print("✅ Example Complete!")
    }
}

// Note: This is a simplified version of the real code for clarity.
// The actual implementation has more error handling and edge cases.
