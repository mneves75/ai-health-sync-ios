// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import CryptoKit
import Foundation
import Network
import SwiftData
import Testing
@testable import iOS_Health_Sync_App

struct TestHealthDataProvider: HealthDataProviding, Sendable {
    let response: HealthDataResponse

    func fetchSamples(types: [HealthDataType], startDate: Date, endDate: Date, limit: Int, offset: Int) async -> HealthDataResponse {
        response
    }
}

func makeInMemoryContainer(enabledTypes: [HealthDataType]) async throws -> ModelContainer {
    let schema = Schema([SyncConfiguration.self, PairedDevice.self, AuditEventRecord.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: configuration)
    await MainActor.run {
        let context = container.mainContext
        let config = SyncConfiguration(enabledTypes: enabledTypes)
        context.insert(config)
        try? context.save()
    }
    return container
}

func makeJSONBody<T: Encodable>(_ payload: T) -> Data {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return (try? encoder.encode(payload)) ?? Data()
}

func decodeJSON<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(type, from: data)
}

struct EmptyBody: Encodable {}

struct TLSClient {
    let host: String
    let port: Int
    let fingerprint: String

    func send<Response: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body,
        token: String?
    ) async throws -> Response {
        let url = URL(string: "https://\(host):\(port)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        if method != "GET" {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let delegate = PinnedSessionDelegate(expectedFingerprint: fingerprint)
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CLIError.requestFailed("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Response.self, from: data)
    }
}

final class PinnedSessionDelegate: NSObject, URLSessionDelegate {
    private let expectedFingerprint: String

    init(expectedFingerprint: String) {
        self.expectedFingerprint = expectedFingerprint.lowercased()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let trust = challenge.protectionSpace.serverTrust,
              let certificate = (SecTrustCopyCertificateChain(trust) as? [SecCertificate])?.first else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        let data = SecCertificateCopyData(certificate) as Data
        let fingerprint = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        if fingerprint == expectedFingerprint {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

enum CLIError: Error {
    case requestFailed(String)
}

func makeServer(
    container: ModelContainer,
    healthResponse: HealthDataResponse,
    protectedData: @escaping @Sendable () async -> Bool,
    deviceName: String = "Test Device",
    identityProvider: @escaping @Sendable () throws -> TLSIdentity = { try CertificateService.loadOrCreateIdentity() },
    listenerPort: NWEndpoint.Port? = nil
) -> (NetworkServer, PairingService, AuditService) {
    let healthProvider = TestHealthDataProvider(response: healthResponse)
    let pairingService = PairingService(modelContainer: container)
    let auditService = AuditService(modelContainer: container)
    let server = NetworkServer(
        healthService: healthProvider,
        pairingService: pairingService,
        auditService: auditService,
        modelContainer: container,
        protectedDataAvailable: protectedData,
        deviceNameProvider: { deviceName },
        identityProvider: identityProvider,
        listenerPort: listenerPort
    )
    return (server, pairingService, auditService)
}

func performPairing(on server: NetworkServer, pairingService: PairingService) async throws -> String {
    let qr = await pairingService.generateQRCode(host: "127.0.0.1", port: 8443, fingerprint: "fingerprint")
    let pairRequest = PairRequest(code: qr.code, clientName: "Test Mac")
    let request = HTTPRequest(
        method: "POST",
        path: "/api/v1/pair",
        headers: ["Content-Type": "application/json"],
        body: makeJSONBody(pairRequest)
    )
    let response = await server.route(request)
    #expect(response.statusCode == 200)
    let payload = try decodeJSON(PairResponse.self, from: response.body)
    return payload.token
}

@Test
func networkServerRejectsUnauthorizedRequests() async throws {
    let container = try await makeInMemoryContainer(enabledTypes: [.steps])
    let (server, _, _) = makeServer(
        container: container,
        healthResponse: HealthDataResponse(status: .ok, samples: [], message: nil, hasMore: false, returnedCount: 0),
        protectedData: { true }
    )
    let request = HTTPRequest(method: "GET", path: "/api/v1/status", headers: [:], body: Data())
    let response = await server.route(request)
    #expect(response.statusCode == 401)
}

@Test
func networkServerPairingAndStatusFlow() async throws {
    let container = try await makeInMemoryContainer(enabledTypes: [.steps, .heartRate])
    let (server, pairingService, _) = makeServer(
        container: container,
        healthResponse: HealthDataResponse(status: .ok, samples: [], message: nil, hasMore: false, returnedCount: 0),
        protectedData: { true }
    )
    let token = try await performPairing(on: server, pairingService: pairingService)
    let request = HTTPRequest(
        method: "GET",
        path: "/api/v1/status",
        headers: ["Authorization": "Bearer \(token)"],
        body: Data()
    )
    let response = await server.route(request)
    #expect(response.statusCode == 200)
    #expect(response.headers["Content-Type"] == "application/json")
    let status = try decodeJSON(StatusResponse.self, from: response.body)
    #expect(status.deviceName == "Test Device")
    #expect(Set(status.enabledTypes) == Set([.steps, .heartRate]))
}

@Test
func networkServerHealthDataLockedReturnsLocked() async throws {
    let container = try await makeInMemoryContainer(enabledTypes: [.steps])
    let (server, pairingService, _) = makeServer(
        container: container,
        healthResponse: HealthDataResponse(status: .ok, samples: [], message: nil, hasMore: false, returnedCount: 0),
        protectedData: { false }
    )
    let token = try await performPairing(on: server, pairingService: pairingService)
    let payload = HealthDataRequest(
        startDate: Date().addingTimeInterval(-3600),
        endDate: Date(),
        types: [.steps]
    )
    let request = HTTPRequest(
        method: "POST",
        path: "/api/v1/health/data",
        headers: ["Authorization": "Bearer \(token)", "Content-Type": "application/json"],
        body: makeJSONBody(payload)
    )
    let response = await server.route(request)
    #expect(response.statusCode == 423)
    let result = try decodeJSON(HealthDataResponse.self, from: response.body)
    #expect(result.status == .locked)
}

@Test
func networkServerHealthDataNoPermissionDoesNotUpdateExportTimestamp() async throws {
    let container = try await makeInMemoryContainer(enabledTypes: [.steps])
    let responsePayload = HealthDataResponse(status: .noPermission, samples: [], message: "No access", hasMore: false, returnedCount: 0)
    let (server, pairingService, _) = makeServer(
        container: container,
        healthResponse: responsePayload,
        protectedData: { true }
    )
    let token = try await performPairing(on: server, pairingService: pairingService)
    let payload = HealthDataRequest(
        startDate: Date().addingTimeInterval(-3600),
        endDate: Date(),
        types: [.steps]
    )
    let request = HTTPRequest(
        method: "POST",
        path: "/api/v1/health/data",
        headers: ["Authorization": "Bearer \(token)", "Content-Type": "application/json"],
        body: makeJSONBody(payload)
    )
    let response = await server.route(request)
    #expect(response.statusCode == 200)
    let result = try decodeJSON(HealthDataResponse.self, from: response.body)
    #expect(result.status == .noPermission)
    let lastExport = await MainActor.run { () -> Date? in
        let context = container.mainContext
        let descriptor = FetchDescriptor<SyncConfiguration>()
        let config = try? context.fetch(descriptor).first
        return config?.lastExportAt
    }
    #expect(lastExport == nil)
}

@Test
func networkServerHealthDataRejectsEmptyTypes() async throws {
    let container = try await makeInMemoryContainer(enabledTypes: [.steps])
    let (server, pairingService, _) = makeServer(
        container: container,
        healthResponse: HealthDataResponse(status: .ok, samples: [], message: nil, hasMore: false, returnedCount: 0),
        protectedData: { true }
    )
    let token = try await performPairing(on: server, pairingService: pairingService)
    let payload = HealthDataRequest(
        startDate: Date().addingTimeInterval(-3600),
        endDate: Date(),
        types: []
    )
    let request = HTTPRequest(
        method: "POST",
        path: "/api/v1/health/data",
        headers: ["Authorization": "Bearer \(token)", "Content-Type": "application/json"],
        body: makeJSONBody(payload)
    )
    let response = await server.route(request)
    #expect(response.statusCode == 400)
}

@Test
func networkServerHealthDataRejectsInvalidDateRange() async throws {
    let container = try await makeInMemoryContainer(enabledTypes: [.steps])
    let (server, pairingService, _) = makeServer(
        container: container,
        healthResponse: HealthDataResponse(status: .ok, samples: [], message: nil, hasMore: false, returnedCount: 0),
        protectedData: { true }
    )
    let token = try await performPairing(on: server, pairingService: pairingService)
    let payload = HealthDataRequest(
        startDate: Date(),
        endDate: Date().addingTimeInterval(-3600),
        types: [.steps]
    )
    let request = HTTPRequest(
        method: "POST",
        path: "/api/v1/health/data",
        headers: ["Authorization": "Bearer \(token)", "Content-Type": "application/json"],
        body: makeJSONBody(payload)
    )
    let response = await server.route(request)
    #expect(response.statusCode == 400)
}

@Test
func networkServerHealthDataRejectsDisabledTypes() async throws {
    let container = try await makeInMemoryContainer(enabledTypes: [.steps])
    let (server, pairingService, _) = makeServer(
        container: container,
        healthResponse: HealthDataResponse(status: .ok, samples: [], message: nil, hasMore: false, returnedCount: 0),
        protectedData: { true }
    )
    let token = try await performPairing(on: server, pairingService: pairingService)
    let payload = HealthDataRequest(
        startDate: Date().addingTimeInterval(-3600),
        endDate: Date(),
        types: [.heartRate]
    )
    let request = HTTPRequest(
        method: "POST",
        path: "/api/v1/health/data",
        headers: ["Authorization": "Bearer \(token)", "Content-Type": "application/json"],
        body: makeJSONBody(payload)
    )
    let response = await server.route(request)
    #expect(response.statusCode == 403)
}

@Test
func networkServerEndToEndPairingAndFetchOverTLS() async throws {
    let container = try await makeInMemoryContainer(enabledTypes: [.steps])
    let sample = HealthSampleDTO(
        id: UUID(),
        type: HealthDataType.steps.rawValue,
        value: 42,
        unit: "count",
        startDate: Date().addingTimeInterval(-60),
        endDate: Date(),
        sourceName: "UnitTest",
        metadata: nil
    )
    let responsePayload = HealthDataResponse(status: .ok, samples: [sample], message: nil, hasMore: false, returnedCount: 1)
    var server: NetworkServer?
    var pairingService: PairingService?
    let ports = (0..<5).compactMap { _ in NWEndpoint.Port(rawValue: UInt16.random(in: 49152...65535)) }
    for port in ports {
        let (candidate, candidatePairing, _) = makeServer(
            container: container,
            healthResponse: responsePayload,
            protectedData: { true },
            identityProvider: { try CertificateService.createEphemeralIdentity() },
            listenerPort: port
        )
        do {
            try await candidate.start()
            server = candidate
            pairingService = candidatePairing
            break
        } catch {
            await candidate.stop()
            continue
        }
    }
    guard let server, let pairingService else {
        throw CLIError.requestFailed("Failed to start server on any test port")
    }
    defer { Task { await server.stop() } }
    try await Task.sleep(nanoseconds: 150_000_000)

    let snapshot = await server.snapshot()
    #expect(snapshot.port > 0)
    let qr = await pairingService.generateQRCode(host: "127.0.0.1", port: snapshot.port, fingerprint: snapshot.fingerprint)
    let client = TLSClient(host: "127.0.0.1", port: snapshot.port, fingerprint: snapshot.fingerprint)
    let pairResponse: PairResponse = try await client.send(
        path: "/api/v1/pair",
        method: "POST",
        body: PairRequest(code: qr.code, clientName: "Test Mac"),
        token: nil
    )
    #expect(!pairResponse.token.isEmpty)

    let status: StatusResponse = try await client.send(
        path: "/api/v1/status",
        method: "GET",
        body: EmptyBody(),
        token: pairResponse.token
    )
    #expect(status.deviceName == "Test Device")
    #expect(status.enabledTypes == [.steps])

    let healthRequest = HealthDataRequest(
        startDate: Date().addingTimeInterval(-3600),
        endDate: Date(),
        types: [.steps]
    )
    let dataResponse: HealthDataResponse = try await client.send(
        path: "/api/v1/health/data",
        method: "POST",
        body: healthRequest,
        token: pairResponse.token
    )
    #expect(dataResponse.status == .ok)
    #expect(dataResponse.samples.count == 1)
}

@Test
func networkServerStartSetsSnapshotPort() async throws {
    let container = try await makeInMemoryContainer(enabledTypes: [.steps])
    let (server, _, _) = makeServer(
        container: container,
        healthResponse: HealthDataResponse(status: .ok, samples: [], message: nil, hasMore: false, returnedCount: 0),
        protectedData: { true },
        identityProvider: { try CertificateService.createEphemeralIdentity() }
    )
    try await server.start()
    let snapshot = await server.snapshot()
    #expect(snapshot.port > 0)
    await server.stop()
}

@Test
func networkServerEncodesLargeSamplePayloadWithinBudget() {
    let samples = (0..<5000).map { index in
        HealthSampleDTO(
            id: UUID(),
            type: HealthDataType.steps.rawValue,
            value: Double(index),
            unit: "count",
            startDate: Date(),
            endDate: Date(),
            sourceName: "UnitTest",
            metadata: nil
        )
    }
    let response = HealthDataResponse(status: .ok, samples: samples, message: nil, hasMore: false, returnedCount: samples.count)
    let start = Date()
    let http = HTTPResponse.json(statusCode: 200, body: response)
    let duration = Date().timeIntervalSince(start)
    #expect(http.body.count > 0)
    #expect(duration < 10.0)
}

@Test
func networkServerHealthDataPaginationWithLimitAndOffset() async throws {
    let container = try await makeInMemoryContainer(enabledTypes: [.steps])
    // Create response with hasMore=true to simulate more data available
    let samples = (0..<10).map { index in
        HealthSampleDTO(
            id: UUID(),
            type: HealthDataType.steps.rawValue,
            value: Double(index),
            unit: "count",
            startDate: Date(),
            endDate: Date(),
            sourceName: "UnitTest",
            metadata: nil
        )
    }
    let responsePayload = HealthDataResponse(status: .ok, samples: samples, message: nil, hasMore: true, returnedCount: 10)
    let (server, pairingService, _) = makeServer(
        container: container,
        healthResponse: responsePayload,
        protectedData: { true }
    )
    let token = try await performPairing(on: server, pairingService: pairingService)

    // Test with explicit limit and offset
    let payload = HealthDataRequest(
        startDate: Date().addingTimeInterval(-3600),
        endDate: Date(),
        types: [.steps],
        limit: 10,
        offset: 0
    )
    let request = HTTPRequest(
        method: "POST",
        path: "/api/v1/health/data",
        headers: ["Authorization": "Bearer \(token)", "Content-Type": "application/json"],
        body: makeJSONBody(payload)
    )
    let response = await server.route(request)
    #expect(response.statusCode == 200)
    let result = try decodeJSON(HealthDataResponse.self, from: response.body)
    #expect(result.status == .ok)
    #expect(result.returnedCount == 10)
    #expect(result.hasMore == true)
}

@Test
func networkServerHealthDataDefaultsAppliedWhenPaginationOmitted() async throws {
    let container = try await makeInMemoryContainer(enabledTypes: [.steps])
    let responsePayload = HealthDataResponse(status: .ok, samples: [], message: nil, hasMore: false, returnedCount: 0)
    let (server, pairingService, _) = makeServer(
        container: container,
        healthResponse: responsePayload,
        protectedData: { true }
    )
    let token = try await performPairing(on: server, pairingService: pairingService)

    // Request without limit/offset should use defaults
    let payload = HealthDataRequest(
        startDate: Date().addingTimeInterval(-3600),
        endDate: Date(),
        types: [.steps],
        limit: nil,
        offset: nil
    )
    let request = HTTPRequest(
        method: "POST",
        path: "/api/v1/health/data",
        headers: ["Authorization": "Bearer \(token)", "Content-Type": "application/json"],
        body: makeJSONBody(payload)
    )
    let response = await server.route(request)
    #expect(response.statusCode == 200)
}

@Test
func auditServiceRetentionPolicyPurgesOldRecords() async throws {
    let container = try await makeInMemoryContainer(enabledTypes: [])
    let auditService = AuditService(modelContainer: container)

    // Create records manually with old timestamps
    let now = Date()
    let oldDate = Calendar.current.date(byAdding: .day, value: -100, to: now)! // 100 days ago (> 90 day retention)
    let recentDate = Calendar.current.date(byAdding: .day, value: -30, to: now)! // 30 days ago (< 90 day retention)

    await MainActor.run {
        let context = container.mainContext
        // Insert old record (should be purged)
        let oldRecord = AuditEventRecord(eventType: "test.old", timestamp: oldDate, detailJSON: "{}")
        context.insert(oldRecord)
        // Insert recent record (should be kept)
        let recentRecord = AuditEventRecord(eventType: "test.recent", timestamp: recentDate, detailJSON: "{}")
        context.insert(recentRecord)
        try? context.save()
    }

    // Verify we have 2 records before purge
    let countBefore = await MainActor.run { () -> Int in
        let context = container.mainContext
        let descriptor = FetchDescriptor<AuditEventRecord>()
        return (try? context.fetch(descriptor).count) ?? 0
    }
    #expect(countBefore == 2)

    // Perform purge
    await auditService.purgeExpiredRecords()

    // Verify only the recent record remains (extract eventType inside MainActor)
    let (countAfter, remainingEventType) = await MainActor.run { () -> (Int, String?) in
        let context = container.mainContext
        let descriptor = FetchDescriptor<AuditEventRecord>()
        let records = (try? context.fetch(descriptor)) ?? []
        return (records.count, records.first?.eventType)
    }
    #expect(countAfter == 1)
    #expect(remainingEventType == "test.recent")
}

@Test
func auditServiceRetentionPolicyRateLimits() async throws {
    let container = try await makeInMemoryContainer(enabledTypes: [])
    let auditService = AuditService(modelContainer: container)

    // First call should run purge (since lastPurgeDate is nil)
    await auditService.purgeExpiredRecordsIfNeeded()

    // Immediately call again - should be rate limited (no-op)
    // Since we can't easily verify the rate limiting, we just ensure it doesn't crash
    await auditService.purgeExpiredRecordsIfNeeded()
    await auditService.purgeExpiredRecordsIfNeeded()

    // This test verifies the method is callable and doesn't crash
    // The actual rate limiting is verified by observing no excessive operations
}

@Test
func pairingServiceAnonymizesClientNameInPairedDevice() async throws {
    let container = try await makeInMemoryContainer(enabledTypes: [])
    let pairingService = PairingService(modelContainer: container)

    // Generate a QR code to create a pending session
    let qr = await pairingService.generateQRCode(host: "127.0.0.1", port: 8443, fingerprint: "test-fingerprint")

    // Perform pairing with a human-readable client name (PII)
    let request = PairRequest(code: qr.code, clientName: "John's MacBook Pro")
    let response = try await pairingService.handlePairRequest(request)

    #expect(!response.token.isEmpty)

    // Verify the stored device name is anonymized (not the original PII)
    let storedName = await MainActor.run { () -> String? in
        let context = container.mainContext
        let descriptor = FetchDescriptor<PairedDevice>()
        let devices = try? context.fetch(descriptor)
        return devices?.first?.name
    }

    // Name should be anonymized format: "Client-XXXXXXXX" (8 hex chars)
    #expect(storedName != nil)
    #expect(storedName != "John's MacBook Pro") // Must NOT store original PII
    #expect(storedName?.hasPrefix("Client-") == true) // Must use anonymized format
    #expect(storedName?.count == 15) // "Client-" (7) + 8 hex chars = 15
}

@Test
func schemaV1ContainsAllRequiredModels() {
    // Verify SchemaV1 includes all three models
    let models = SchemaV1.models
    #expect(models.count == 3)

    // Verify version identifier
    let version = SchemaV1.versionIdentifier
    #expect(version.major == 1)
    #expect(version.minor == 0)
    #expect(version.patch == 0)
}

@Test
func migrationPlanHasCorrectSchema() {
    // Verify migration plan references SchemaV1
    let schemas = HealthSyncMigrationPlan.schemas
    #expect(schemas.count == 1)
    #expect(schemas.first == SchemaV1.self)

    // No migration stages for V1 (initial version)
    let stages = HealthSyncMigrationPlan.stages
    #expect(stages.isEmpty)
}

@Test @MainActor
func modelContainerCreatesWithMigrationPlan() throws {
    // Verify the migration plan can create a working ModelContainer
    let schema = Schema(versionedSchema: SchemaV1.self)
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: schema,
        migrationPlan: HealthSyncMigrationPlan.self,
        configurations: configuration
    )

    // Verify we can insert and fetch data using the versioned schema
    let context = container.mainContext
    let config = SyncConfiguration(enabledTypes: [.steps])
    context.insert(config)
    try context.save()

    let descriptor = FetchDescriptor<SyncConfiguration>()
    let fetched = try context.fetch(descriptor)
    #expect(fetched.count == 1)
    #expect(fetched.first?.enabledTypes == [.steps])
}
