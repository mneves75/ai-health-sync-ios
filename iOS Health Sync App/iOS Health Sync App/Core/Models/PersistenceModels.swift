// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation
import SwiftData

@Model
final class SyncConfiguration {
    @Attribute(.unique) var id: UUID
    var enabledTypesCSV: String
    var lastExportAt: Date?
    var createdAt: Date

    init(id: UUID = UUID(), enabledTypes: [HealthDataType] = HealthDataType.allCases, lastExportAt: Date? = nil, createdAt: Date = Date()) {
        self.id = id
        self.enabledTypesCSV = Self.serialize(types: enabledTypes)
        self.lastExportAt = lastExportAt
        self.createdAt = createdAt
    }

    var enabledTypes: [HealthDataType] {
        get { Self.deserialize(csv: enabledTypesCSV) }
        set { enabledTypesCSV = Self.serialize(types: newValue) }
    }

    static func serialize(types: [HealthDataType]) -> String {
        types.map { $0.rawValue }.sorted().joined(separator: ",")
    }

    static func deserialize(csv: String) -> [HealthDataType] {
        csv.split(separator: ",").compactMap { HealthDataType(rawValue: String($0)) }
    }
}

@Model
final class PairedDevice {
    @Attribute(.unique) var id: UUID
    var name: String
    var tokenHash: String
    var createdAt: Date
    var expiresAt: Date
    var lastSeenAt: Date?
    var isActive: Bool

    init(id: UUID = UUID(), name: String, tokenHash: String, createdAt: Date = Date(), expiresAt: Date, lastSeenAt: Date? = nil, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.tokenHash = tokenHash
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.lastSeenAt = lastSeenAt
        self.isActive = isActive
    }
}

@Model
final class AuditEventRecord {
    @Attribute(.unique) var id: UUID
    var eventType: String
    var timestamp: Date
    var detailJSON: String

    init(id: UUID = UUID(), eventType: String, timestamp: Date = Date(), detailJSON: String) {
        self.id = id
        self.eventType = eventType
        self.timestamp = timestamp
        self.detailJSON = detailJSON
    }
}
