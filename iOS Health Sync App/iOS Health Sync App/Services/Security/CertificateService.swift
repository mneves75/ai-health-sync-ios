// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import CryptoKit
import Foundation
import os
import Security

struct TLSIdentity {
    let identity: SecIdentity
    let certificateData: Data
    let fingerprint: String
}

struct CertificateService {
    private static let keyTag = "org.mvneves.healthsync.tlskey"
    private static let certLabel = "HealthSync Local TLS"
    private static let identityQueue = DispatchQueue(label: "org.mvneves.healthsync.tlsidentity")

    static func loadOrCreateIdentity() throws -> TLSIdentity {
        // Serialize identity creation to avoid keychain races during app startup.
        try identityQueue.sync {
            if let existing = try? loadIdentity() {
                return existing
            }

            let privateKey = try createPrivateKey(persist: true)
            let publicKey = SecKeyCopyPublicKey(privateKey)
            guard let publicKey else {
                throw CertificateError.keyGenerationFailed
            }

            let certData = try buildSelfSignedCertificate(privateKey: privateKey, publicKey: publicKey)
            try storeCertificate(certData)

            // Create identity by combining certificate and private key
            guard let certificate = SecCertificateCreateWithData(nil, certData as CFData) else {
                throw CertificateError.notFound
            }
            guard let identity = SecIdentityCreate(nil, certificate, privateKey) else {
                throw CertificateError.identityFailed
            }

            let fingerprint = sha256Fingerprint(certData)
            return TLSIdentity(identity: identity, certificateData: certData, fingerprint: fingerprint)
        }
    }

    static func createEphemeralIdentity() throws -> TLSIdentity {
        let privateKey = try createPrivateKey(persist: false)
        let publicKey = SecKeyCopyPublicKey(privateKey)
        guard let publicKey else {
            throw CertificateError.keyGenerationFailed
        }

        let certData = try buildSelfSignedCertificate(privateKey: privateKey, publicKey: publicKey)
        guard let certificate = SecCertificateCreateWithData(nil, certData as CFData) else {
            throw CertificateError.notFound
        }
        guard let identity = SecIdentityCreate(nil, certificate, privateKey) else {
            throw CertificateError.identityFailed
        }
        let fingerprint = sha256Fingerprint(certData)
        return TLSIdentity(identity: identity, certificateData: certData, fingerprint: fingerprint)
    }

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
        guard certStatus == errSecSuccess, let certData = certItem as? Data else {
            throw CertificateError.notFound
        }

        guard let certificate = SecCertificateCreateWithData(nil, certData as CFData) else {
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
        guard keyStatus == errSecSuccess, let keyItem else {
            throw CertificateError.notFound
        }
        let privateKey = keyItem as! SecKey

        // Create identity by combining certificate and private key
        guard let identity = SecIdentityCreate(nil, certificate, privateKey) else {
            throw CertificateError.identityFailed
        }

        let fingerprint = sha256Fingerprint(certData)
        return TLSIdentity(identity: identity, certificateData: certData, fingerprint: fingerprint)
    }

    private static func createPrivateKey(persist: Bool) throws -> SecKey {
        if !persist {
            let attributes: [String: Any] = [
                kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits as String: 256
            ]
            var error: Unmanaged<CFError>?
            guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
                if let error = error {
                    AppLoggers.security.error("Failed to create ephemeral key: \(error.takeRetainedValue().localizedDescription, privacy: .public)")
                }
                throw CertificateError.keyGenerationFailed
            }
            return key
        }

        let tagData = keyTag.data(using: .utf8) ?? Data()
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrApplicationTag as String: tagData,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let item {
            // CFTypeRef is opaque, directly cast to SecKey (type verified by query attributes)
            return (item as! SecKey)
        }

        let baseAttributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tagData,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
        ]

        if SecureEnclave.isAvailable {
            var enclaveAttributes = baseAttributes
            enclaveAttributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
            if let key = SecKeyCreateRandomKey(enclaveAttributes as CFDictionary, nil) {
                return key
            }
        }

        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey(baseAttributes as CFDictionary, &error) else {
            if let error = error {
                AppLoggers.security.error("Failed to create private key: \(error.takeRetainedValue().localizedDescription, privacy: .public)")
            }
            throw CertificateError.keyGenerationFailed
        }
        return key
    }

    private static func buildSelfSignedCertificate(privateKey: SecKey, publicKey: SecKey) throws -> Data {
        let publicKeyData = try externalRepresentation(for: publicKey)
        let notBefore = Date()
        let notAfter = Calendar.current.date(byAdding: .day, value: 365, to: notBefore) ?? notBefore.addingTimeInterval(60 * 60 * 24 * 365)

        let serial = UInt64.random(in: 1...UInt64.max)
        let tbs = buildTBSCertificate(serial: serial, publicKeyData: publicKeyData, notBefore: notBefore, notAfter: notAfter)

        let signature = try sign(data: tbs, with: privateKey)
        let signatureAlgorithm = DEREncoder.sequence([
            DEREncoder.objectIdentifier([1, 2, 840, 10045, 4, 3, 2]),
            DEREncoder.null()
        ])

        let certificate = DEREncoder.sequence([
            tbs,
            signatureAlgorithm,
            DEREncoder.bitString(signature)
        ])

        return certificate
    }

    private static func buildTBSCertificate(serial: UInt64, publicKeyData: Data, notBefore: Date, notAfter: Date) -> Data {
        let version = DEREncoder.contextSpecific(0, content: DEREncoder.integer(2))
        let serialNumber = DEREncoder.integer(serial.bytes)
        let signatureAlgorithm = DEREncoder.sequence([
            DEREncoder.objectIdentifier([1, 2, 840, 10045, 4, 3, 2]),
            DEREncoder.null()
        ])

        let name = DEREncoder.sequence([
            DEREncoder.set([
                DEREncoder.sequence([
                    DEREncoder.objectIdentifier([2, 5, 4, 3]),
                    DEREncoder.utf8String("HealthSync Local")
                ])
            ])
        ])

        let validity = DEREncoder.sequence([
            DEREncoder.utcTime(notBefore),
            DEREncoder.utcTime(notAfter)
        ])

        let publicKeyAlgorithm = DEREncoder.sequence([
            DEREncoder.objectIdentifier([1, 2, 840, 10045, 2, 1]),
            DEREncoder.objectIdentifier([1, 2, 840, 10045, 3, 1, 7])
        ])

        let subjectPublicKeyInfo = DEREncoder.sequence([
            publicKeyAlgorithm,
            DEREncoder.bitString(publicKeyData)
        ])

        return DEREncoder.sequence([
            version,
            serialNumber,
            signatureAlgorithm,
            name,
            validity,
            name,
            subjectPublicKeyInfo
        ])
    }

    private static func sign(data: Data, with privateKey: SecKey) throws -> Data {
        let algorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            throw CertificateError.signatureFailed
        }
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(privateKey, algorithm, data as CFData, &error) as Data? else {
            if let error = error {
                AppLoggers.security.error("Failed to sign certificate: \(error.takeRetainedValue().localizedDescription, privacy: .public)")
            }
            throw CertificateError.signatureFailed
        }
        return signature
    }

    private static func externalRepresentation(for key: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(key, &error) as Data? else {
            if let error = error {
                AppLoggers.security.error("Failed to export key: \(error.takeRetainedValue().localizedDescription, privacy: .public)")
            }
            throw CertificateError.keyExportFailed
        }
        return data
    }

    private static func storeCertificate(_ data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: certLabel,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CertificateError.storeFailed
        }
    }

    private static func sha256Fingerprint(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

enum CertificateError: Error {
    case notFound
    case keyGenerationFailed
    case keyExportFailed
    case signatureFailed
    case storeFailed
    case identityFailed
}

private extension UInt64 {
    var bytes: [UInt8] {
        var value = self
        var bytes = [UInt8]()
        repeat {
            bytes.insert(UInt8(value & 0xFF), at: 0)
            value >>= 8
        } while value > 0
        return bytes
    }
}
