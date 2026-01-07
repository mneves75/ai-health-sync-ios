// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation

struct HealthSampleDTO: Codable, Sendable, Identifiable {
    let id: UUID
    let type: String
    let value: Double
    let unit: String
    let startDate: Date
    let endDate: Date
    let sourceName: String
    let metadata: [String: String]?
}

enum HealthDataStatus: String, Codable, Sendable {
    case ok
    case noPermission
    case locked
    case error
}

struct HealthDataResponse: Codable, Sendable {
    let status: HealthDataStatus
    let samples: [HealthSampleDTO]
    let message: String?
    var hasMore: Bool = false
    var returnedCount: Int = 0
}

struct HealthDataRequest: Codable, Sendable {
    let startDate: Date
    let endDate: Date
    let types: [HealthDataType]
    var limit: Int? = nil
    var offset: Int? = nil
}

struct StatusResponse: Codable, Sendable {
    let status: String
    let version: String
    let deviceName: String
    let enabledTypes: [HealthDataType]
    let serverTime: Date
}

struct TypesResponse: Codable, Sendable {
    let enabledTypes: [HealthDataType]
}

struct PairRequest: Codable, Sendable {
    let code: String
    let clientName: String
}

struct PairResponse: Codable, Sendable {
    let token: String
    let expiresAt: Date
}

struct PairingQRCode: Codable, Sendable {
    let version: String
    let host: String
    let port: Int
    let code: String
    let expiresAt: Date
    let certificateFingerprint: String
}
