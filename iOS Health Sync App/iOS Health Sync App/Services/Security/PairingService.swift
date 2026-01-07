// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import CryptoKit
import Foundation
import os
import SwiftData

actor PairingService {
    private let modelContainer: ModelContainer
    private var pendingSession: PendingPairing?
    private let tokenTTL: TimeInterval = 60 * 60 * 24 * 30

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func generateQRCode(host: String, port: Int, fingerprint: String) -> PairingQRCode {
        // Use 8-character alphanumeric code (62^8 = 218 trillion combinations)
        // vs 6-digit numeric (10^6 = 1 million combinations)
        let code = Self.generateSecureCode(length: 8)
        let expiresAt = Date().addingTimeInterval(60 * 5)
        pendingSession = PendingPairing(code: code, expiresAt: expiresAt, failedAttempts: 0)
        return PairingQRCode(
            version: "1",
            host: host,
            port: port,
            code: code,
            expiresAt: expiresAt,
            certificateFingerprint: fingerprint
        )
    }

    func handlePairRequest(_ request: PairRequest) async throws -> PairResponse {
        guard var session = pendingSession else {
            throw PairingError.noPendingSession
        }

        // Rate limiting: max 5 attempts, then lock out
        guard session.failedAttempts < 5 else {
            pendingSession = nil
            throw PairingError.tooManyAttempts
        }

        guard session.expiresAt > Date() else {
            pendingSession = nil
            throw PairingError.expiredCode
        }

        // Constant-time comparison to prevent timing attacks
        guard Self.constantTimeCompare(session.code, request.code) else {
            session.failedAttempts += 1
            pendingSession = session
            throw PairingError.invalidCode
        }

        let token = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let tokenHash = Self.hashToken(token)
        let expiresAt = Date().addingTimeInterval(tokenTTL)

        // Anonymize client name to prevent PII storage
        // Format: "Client-XXXXXXXX" using first 8 chars of SHA256 hash
        let anonymizedName = Self.anonymizeName(request.clientName)
        await persistPairedDevice(name: anonymizedName, tokenHash: tokenHash, expiresAt: expiresAt)
        pendingSession = nil
        return PairResponse(token: token, expiresAt: expiresAt)
    }

    func validateToken(_ token: String) async -> Bool {
        let hash = Self.hashToken(token)
        return await MainActor.run {
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<PairedDevice>(predicate: #Predicate { $0.tokenHash == hash && $0.isActive })
            let result: [PairedDevice]
            do {
                result = try context.fetch(descriptor)
            } catch {
                AppLoggers.security.error("Failed to fetch paired device: \(error.localizedDescription, privacy: .public)")
                return false
            }
            guard let device = result.first else { return false }
            guard device.expiresAt > Date() else { return false }
            device.lastSeenAt = Date()
            do {
                try context.save()
            } catch {
                AppLoggers.security.error("Failed to update device lastSeenAt: \(error.localizedDescription, privacy: .public)")
            }
            return true
        }
    }

    func revokeAll() async {
        await MainActor.run {
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<PairedDevice>()
            let devices: [PairedDevice]
            do {
                devices = try context.fetch(descriptor)
            } catch {
                AppLoggers.security.error("Failed to fetch devices for revocation: \(error.localizedDescription, privacy: .public)")
                return
            }
            for device in devices {
                device.isActive = false
            }
            do {
                try context.save()
            } catch {
                AppLoggers.security.error("Failed to save revoked devices: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func persistPairedDevice(name: String, tokenHash: String, expiresAt: Date) async {
        await MainActor.run {
            let context = modelContainer.mainContext
            let device = PairedDevice(name: name, tokenHash: tokenHash, expiresAt: expiresAt)
            context.insert(device)
            do {
                try context.save()
            } catch {
                AppLoggers.security.error("Failed to persist paired device: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private static func hashToken(_ token: String) -> String {
        let digest = SHA256.hash(data: Data(token.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func generateSecureCode(length: Int) -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789"
        // Excluded similar-looking characters: I, l, O, 0, 1
        var code = ""
        for _ in 0..<length {
            let randomIndex = Int.random(in: 0..<chars.count)
            code.append(chars[chars.index(chars.startIndex, offsetBy: randomIndex)])
        }
        return code
    }

    private static func constantTimeCompare(_ a: String, _ b: String) -> Bool {
        guard a.count == b.count else { return false }
        let aBytes = Array(a.utf8)
        let bBytes = Array(b.utf8)
        var result: UInt8 = 0
        for i in 0..<aBytes.count {
            result |= aBytes[i] ^ bBytes[i]
        }
        return result == 0
    }

    private static func anonymizeName(_ name: String) -> String {
        let hash = SHA256.hash(data: Data(name.utf8))
        let shortHash = hash.prefix(4).map { String(format: "%02x", $0) }.joined()
        return "Client-\(shortHash.uppercased())"
    }
}

struct PendingPairing: Sendable {
    let code: String
    let expiresAt: Date
    var failedAttempts: Int
}

/// Errors that can occur during device pairing.
/// Each case provides a user-friendly message for debugging.
enum PairingError: Error, LocalizedError {
    case noPendingSession
    case invalidCode
    case expiredCode
    case tooManyAttempts

    var errorDescription: String? {
        switch self {
        case .noPendingSession:
            return "No pairing session active. Generate a new QR code in the iOS app."
        case .invalidCode:
            return "Invalid pairing code. Check that you copied the latest QR code."
        case .expiredCode:
            return "Pairing code expired (5 min TTL). Generate a new QR code."
        case .tooManyAttempts:
            return "Too many failed attempts. Restart the iOS app to try again."
        }
    }
}
