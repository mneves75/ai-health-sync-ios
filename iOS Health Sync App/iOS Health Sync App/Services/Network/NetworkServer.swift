// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import CryptoKit
import Foundation
import Network
import os
import Security
import SwiftData

actor NetworkServer {
    private let healthService: HealthDataProviding
    private let pairingService: PairingService
    private let auditService: AuditService
    private let modelContainer: ModelContainer
    private let protectedDataAvailable: @Sendable () async -> Bool
    private let deviceNameProvider: @Sendable () async -> String
    private let identityProvider: @Sendable () throws -> TLSIdentity

    private var listener: NWListener?
    private(set) var port: Int = 0
    private(set) var certificateFingerprint: String = ""
    private var requestLog: [String: [Date]] = [:]
    private let rateLimit = 60
    private let rateWindow: TimeInterval = 60
    private let maxHeadersBytes = 16_384
    private let maxBodyBytes = 1_048_576
    private let maxRequestDuration: TimeInterval = 10
    private let startTimeout: TimeInterval = 5
    private let listenerPortOverride: NWEndpoint.Port?

    init(
        healthService: HealthDataProviding,
        pairingService: PairingService,
        auditService: AuditService,
        modelContainer: ModelContainer,
        protectedDataAvailable: @escaping @Sendable () async -> Bool,
        deviceNameProvider: @escaping @Sendable () async -> String,
        identityProvider: @escaping @Sendable () throws -> TLSIdentity = { try CertificateService.loadOrCreateIdentity() },
        listenerPort: NWEndpoint.Port? = nil
    ) {
        self.healthService = healthService
        self.pairingService = pairingService
        self.auditService = auditService
        self.modelContainer = modelContainer
        self.protectedDataAvailable = protectedDataAvailable
        self.deviceNameProvider = deviceNameProvider
        self.identityProvider = identityProvider
        self.listenerPortOverride = listenerPort
    }

    func start() async throws {
        if listener != nil { return }
        let identity = try identityProvider()
        certificateFingerprint = identity.fingerprint

        let tlsOptions = NWProtocolTLS.Options()
        sec_protocol_options_set_min_tls_protocol_version(tlsOptions.securityProtocolOptions, .TLSv13)
        if let secIdentity = sec_identity_create(identity.identity) {
            sec_protocol_options_set_local_identity(tlsOptions.securityProtocolOptions, secIdentity)
        }

        let parameters = NWParameters(tls: tlsOptions)
        parameters.allowLocalEndpointReuse = true
        let listener = try NWListener(using: parameters, on: listenerPortOverride ?? .any)
        let deviceName = await deviceNameProvider()
        listener.service = NWListener.Service(name: deviceName, type: "_healthsync._tcp")

        listener.newConnectionHandler = { [weak self] connection in
            guard let self else { return }
            Task { await self.handleConnection(connection) }
        }

        try await awaitReady(listener, queue: .global())
        let effectivePort = listener.port ?? listenerPortOverride
        guard let port = effectivePort else {
            listener.cancel()
            throw NetworkServerError.startTimeout
        }
        self.listener = listener
        self.port = Int(port.rawValue)
    }

    func stop() {
        listener?.cancel()
        listener = nil
        port = 0
    }

    func snapshot() -> (port: Int, fingerprint: String) {
        (port: port, fingerprint: certificateFingerprint)
    }

    private func handleConnection(_ connection: NWConnection) async {
        connection.stateUpdateHandler = { state in
            if case .failed(let error) = state {
                AppLoggers.network.error("Connection failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        connection.start(queue: .global())

        defer { connection.cancel() }
        do {
            let request = try await receiveRequest(on: connection)
            let response = await route(request)
            await send(response: response, on: connection)
        } catch let error as HTTPParseError {
            let response: HTTPResponse
            switch error {
            case .bodyTooLarge:
                response = HTTPResponse.plain(statusCode: 413, reason: "Payload Too Large", message: "Request body too large")
            case .incomplete:
                response = HTTPResponse.plain(statusCode: 408, reason: "Request Timeout", message: "Request incomplete or timed out")
            case .invalidRequest:
                response = HTTPResponse.plain(statusCode: 400, reason: "Bad Request", message: "Invalid request")
            }
            await send(response: response, on: connection)
        } catch {
            let response = HTTPResponse.plain(statusCode: 400, reason: "Bad Request", message: "Invalid request")
            await send(response: response, on: connection)
        }
    }

    func route(_ request: HTTPRequest) async -> HTTPResponse {
        let path = request.path
        let method = request.method
        let requestId = UUID().uuidString

        if path == "/api/v1/pair" && method == "POST" {
            return await handlePair(request, requestId: requestId)
        }

        guard let token = bearerToken(from: request.headers), await pairingService.validateToken(token) else {
            await auditService.record(eventType: "security.unauthorized_access", details: [
                "path": path,
                "requestId": requestId
            ])
            return HTTPResponse.plain(statusCode: 401, reason: "Unauthorized", message: "Missing or invalid token")
        }
        if isRateLimited(token: token) {
            await auditService.record(eventType: "security.rate_limit_exceeded", details: [
                "path": path,
                "requestId": requestId
            ])
            return HTTPResponse.plain(statusCode: 429, reason: "Too Many Requests", message: "Rate limit exceeded")
        }

        switch (method, path) {
        case ("GET", "/api/v1/status"):
            return await handleStatus(requestId: requestId)
        case ("GET", "/api/v1/health/types"):
            return await handleTypes(requestId: requestId)
        case ("POST", "/api/v1/health/data"):
            return await handleHealthData(request, requestId: requestId)
        default:
            return HTTPResponse.plain(statusCode: 404, reason: "Not Found", message: "Unknown route")
        }
    }

    private func handlePair(_ request: HTTPRequest, requestId: String) async -> HTTPResponse {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(PairRequest.self, from: request.body)
            let response = try await pairingService.handlePairRequest(payload)
            let clientHash = Self.hashString(payload.clientName)
            await auditService.record(eventType: "auth.pair", details: [
                "clientHash": clientHash,
                "requestId": requestId
            ])
            return HTTPResponse.json(statusCode: 200, body: response)
        } catch let pairingError as PairingError {
            // Return specific error message to help CLI users debug
            await auditService.record(eventType: "security.unauthorized_access", details: [
                "path": "/api/v1/pair",
                "error": String(describing: pairingError),
                "requestId": requestId
            ])
            return HTTPResponse.plain(
                statusCode: 400,
                reason: "Bad Request",
                message: pairingError.localizedDescription
            )
        } catch {
            // Unexpected error (e.g., JSON decode failure)
            await auditService.record(eventType: "security.unauthorized_access", details: [
                "path": "/api/v1/pair",
                "error": "decode_error",
                "requestId": requestId
            ])
            return HTTPResponse.plain(statusCode: 400, reason: "Bad Request", message: "Invalid request format")
        }
    }

    private func handleStatus(requestId: String) async -> HTTPResponse {
        let enabled = await loadEnabledTypes()
        let response = StatusResponse(
            status: "ok",
            version: "1",
            deviceName: await deviceNameProvider(),
            enabledTypes: enabled,
            serverTime: Date()
        )
        await auditService.record(eventType: "api.request", details: [
            "path": "/api/v1/status",
            "requestId": requestId
        ])
        return HTTPResponse.json(statusCode: 200, body: response)
    }

    private func handleTypes(requestId: String) async -> HTTPResponse {
        let enabled = await loadEnabledTypes()
        let response = TypesResponse(enabledTypes: enabled)
        await auditService.record(eventType: "api.request", details: [
            "path": "/api/v1/health/types",
            "requestId": requestId
        ])
        return HTTPResponse.json(statusCode: 200, body: response)
    }

    /// Default limit for health data queries
    private static let defaultLimit = 1000
    /// Maximum allowed limit per request
    private static let maxLimit = 10_000

    private func handleHealthData(_ request: HTTPRequest, requestId: String) async -> HTTPResponse {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload: HealthDataRequest
        do {
            payload = try decoder.decode(HealthDataRequest.self, from: request.body)
        } catch {
            return HTTPResponse.plain(statusCode: 400, reason: "Bad Request", message: "Invalid request body")
        }
        if payload.types.isEmpty {
            await auditService.record(eventType: "api.request_invalid", details: [
                "path": "/api/v1/health/data",
                "reason": "empty_types",
                "requestId": requestId
            ])
            return HTTPResponse.plain(statusCode: 400, reason: "Bad Request", message: "No data types requested")
        }
        if payload.endDate < payload.startDate {
            await auditService.record(eventType: "api.request_invalid", details: [
                "path": "/api/v1/health/data",
                "reason": "invalid_date_range",
                "requestId": requestId
            ])
            return HTTPResponse.plain(statusCode: 400, reason: "Bad Request", message: "Invalid date range")
        }

        // Validate and apply pagination defaults
        let limit = min(payload.limit ?? Self.defaultLimit, Self.maxLimit)
        let offset = max(payload.offset ?? 0, 0)

        if limit <= 0 {
            await auditService.record(eventType: "api.request_invalid", details: [
                "path": "/api/v1/health/data",
                "reason": "invalid_limit",
                "requestId": requestId
            ])
            return HTTPResponse.plain(statusCode: 400, reason: "Bad Request", message: "Limit must be positive")
        }

        let enabledTypes = await loadEnabledTypes()
        let enabledSet = Set(enabledTypes)
        let requestedSet = Set(payload.types)
        if !requestedSet.isSubset(of: enabledSet) {
            await auditService.record(eventType: "security.unauthorized_access", details: [
                "path": "/api/v1/health/data",
                "requestId": requestId
            ])
            return HTTPResponse.plain(statusCode: 403, reason: "Forbidden", message: "Requested data types are not enabled")
        }

        let isProtected = await protectedDataAvailable()
        guard isProtected else {
            let response = HealthDataResponse(status: .locked, samples: [], message: "Device is locked", hasMore: false, returnedCount: 0)
            await auditService.record(eventType: "data.read", details: [
                "status": "locked",
                "requestId": requestId
            ])
            return HTTPResponse.json(statusCode: 423, reason: "Locked", body: response)
        }

        let result = await healthService.fetchSamples(types: payload.types, startDate: payload.startDate, endDate: payload.endDate, limit: limit, offset: offset)
        await auditService.record(eventType: "data.read", details: [
            "status": result.status.rawValue,
            "count": String(result.returnedCount),
            "hasMore": String(result.hasMore),
            "requestId": requestId
        ])
        if result.status == .ok {
            await updateLastExport()
        }
        return HTTPResponse.json(statusCode: 200, body: result)
    }

    private func loadEnabledTypes() async -> [HealthDataType] {
        await MainActor.run {
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<SyncConfiguration>()
            do {
                if let config = try context.fetch(descriptor).first {
                    return config.enabledTypes
                }
            } catch {
                AppLoggers.network.error("Failed to load enabled types: \(error.localizedDescription, privacy: .public)")
            }
            return HealthDataType.allCases
        }
    }

    private func updateLastExport() async {
        await MainActor.run {
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<SyncConfiguration>()
            do {
                if let config = try context.fetch(descriptor).first {
                    config.lastExportAt = Date()
                    try context.save()
                }
            } catch {
                AppLoggers.network.error("Failed to update last export: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func bearerToken(from headers: [String: String]) -> String? {
        guard let value = headers["Authorization"] else { return nil }
        let parts = value.split(separator: " ")
        guard parts.count == 2, parts[0].lowercased() == "bearer" else { return nil }
        return String(parts[1])
    }

    private func isRateLimited(token: String) -> Bool {
        let now = Date()
        var entries = requestLog[token, default: []].filter { now.timeIntervalSince($0) < rateWindow }
        if entries.count >= rateLimit {
            requestLog[token] = entries
            return true
        }
        entries.append(now)
        requestLog[token] = entries
        return false
    }

    private func receiveRequest(on connection: NWConnection) async throws -> HTTPRequest {
        var buffer = Data()
        let start = Date()
        while true {
            if Date().timeIntervalSince(start) > maxRequestDuration {
                throw HTTPParseError.incomplete
            }
            let chunk = try await receiveData(on: connection)
            if chunk.isEmpty {
                throw HTTPParseError.incomplete
            }
            buffer.append(chunk)
            if buffer.count > maxHeadersBytes + maxBodyBytes {
                throw HTTPParseError.bodyTooLarge
            }
            if let request = try parseRequest(from: buffer) {
                return request
            }
        }
    }

    private func awaitReady(_ listener: NWListener, queue: DispatchQueue) async throws {
        var continuation: AsyncStream<NWListener.State>.Continuation?
        let stream = AsyncStream<NWListener.State> { streamContinuation in
            continuation = streamContinuation
            listener.stateUpdateHandler = { newState in
                AppLoggers.network.info("Listener state: \(String(describing: newState), privacy: .public)")
                streamContinuation.yield(newState)
            }
        }

        defer {
            continuation?.finish()
            listener.stateUpdateHandler = { newState in
                AppLoggers.network.info("Listener state: \(String(describing: newState), privacy: .public)")
            }
        }

        // Start only after state handler is installed to avoid missing a fast .ready transition.
        listener.start(queue: queue)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                for await state in stream {
                    switch state {
                    case .ready:
                        return
                    case .failed(let error):
                        throw error
                    case .cancelled:
                        throw NetworkServerError.startCancelled
                    default:
                        continue
                    }
                }
                throw NetworkServerError.startTimeout
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(self.startTimeout * 1_000_000_000))
                throw NetworkServerError.startTimeout
            }
            _ = try await group.next()
            group.cancelAll()
        }
    }

    private func receiveData(on connection: NWConnection) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 16_384) { data, _, _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: data ?? Data())
            }
        }
    }

    private func parseRequest(from data: Data) throws -> HTTPRequest? {
        guard let delimiterRange = data.range(of: Data("\r\n\r\n".utf8)) else {
            if data.count > maxHeadersBytes {
                throw HTTPParseError.bodyTooLarge
            }
            return nil
        }
        let headerData = data[..<delimiterRange.lowerBound]
        let bodyData = data[delimiterRange.upperBound...]
        if headerData.count > maxHeadersBytes {
            throw HTTPParseError.bodyTooLarge
        }
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            throw HTTPParseError.invalidRequest
        }
        let lines = headerString.split(separator: "\r\n", omittingEmptySubsequences: false)
        guard let requestLine = lines.first else {
            throw HTTPParseError.invalidRequest
        }
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { throw HTTPParseError.invalidRequest }
        let method = String(parts[0])
        let path = String(parts[1])

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let index = line.firstIndex(of: ":") else { continue }
            let key = line[..<index].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: index)...].trimmingCharacters(in: .whitespaces)
            headers[key] = value
        }

        let contentLength = Int(headers["Content-Length"] ?? "0") ?? 0
        if contentLength > maxBodyBytes {
            throw HTTPParseError.bodyTooLarge
        }
        if bodyData.count < contentLength {
            return nil
        }
        let body = bodyData.prefix(contentLength)
        return HTTPRequest(method: method, path: path, headers: headers, body: Data(body))
    }

    private func send(response: HTTPResponse, on connection: NWConnection) async {
        let data = response.toData()
        await withCheckedContinuation { continuation in
            connection.send(content: data, completion: .contentProcessed { _ in
                continuation.resume()
            })
        }
    }

    private static func hashString(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

enum NetworkServerError: Error {
    case startTimeout
    case startCancelled
}
