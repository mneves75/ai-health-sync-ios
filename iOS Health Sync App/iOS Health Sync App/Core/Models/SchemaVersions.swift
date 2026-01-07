// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation
import SwiftData

// MARK: - Schema Version 1 (Initial)

/// Initial schema version containing all three models.
/// NEVER modify this enum - create a new version instead.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [SyncConfiguration.self, PairedDevice.self, AuditEventRecord.self]
    }
}

// MARK: - Migration Plan

/// Migration plan for HealthSync database.
///
/// ## How to Add Migrations
///
/// When modifying the schema:
/// 1. Create a new `SchemaV{N}` enum with incremented version
/// 2. Add a migration stage from V{N-1} to V{N}
/// 3. Update `schemas` and `stages` arrays
/// 4. Add unit test for the migration
///
/// Example for adding V2:
/// ```swift
/// enum SchemaV2: VersionedSchema {
///     static var versionIdentifier: Schema.Version {
///         Schema.Version(2, 0, 0)
///     }
///     static var models: [any PersistentModel.Type] {
///         [SyncConfigurationV2.self, PairedDevice.self, AuditEventRecord.self]
///     }
/// }
///
/// extension HealthSyncMigrationPlan {
///     static let migrateV1toV2 = MigrationStage.lightweight(
///         fromVersion: SchemaV1.self,
///         toVersion: SchemaV2.self
///     )
/// }
/// ```
///
/// - Important: Never modify existing `SchemaV{N}` enums. Always create new versions.
enum HealthSyncMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // No migrations yet - V1 is the initial version
        []
    }
}
