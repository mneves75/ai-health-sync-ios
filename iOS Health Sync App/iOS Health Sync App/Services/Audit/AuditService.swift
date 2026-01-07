// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation
import os
import SwiftData

actor AuditService {
    private let modelContainer: ModelContainer

    /// Audit log retention period: 90 days (per AUDIT-GUIDELINES.md)
    private static let retentionDays: Int = 90

    /// Minimum interval between purge operations (1 day)
    private static let purgeInterval: TimeInterval = 86_400

    /// Last purge timestamp to avoid excessive cleanup operations
    private var lastPurgeDate: Date?

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func record(eventType: String, details: [String: String]) async {
        let json: String
        do {
            let data = try JSONEncoder().encode(details)
            json = String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            AppLoggers.audit.error("Failed to encode audit details: \(error.localizedDescription, privacy: .public)")
            json = "{}"
        }

        await MainActor.run {
            let context = modelContainer.mainContext
            let record = AuditEventRecord(eventType: eventType, detailJSON: json)
            context.insert(record)
            do {
                try context.save()
            } catch {
                AppLoggers.audit.error("Failed to persist audit record: \(error.localizedDescription, privacy: .public)")
            }
        }

        if let requestId = details["requestId"] {
            AppLoggers.audit.info("Audit event: \(eventType, privacy: .public) requestId=\(requestId, privacy: .public)")
        } else {
            AppLoggers.audit.info("Audit event: \(eventType, privacy: .public)")
        }

        // Perform periodic cleanup
        await purgeExpiredRecordsIfNeeded()
    }

    /// Purges audit records older than the retention period.
    /// Called automatically during record() but rate-limited to once per day.
    func purgeExpiredRecordsIfNeeded() async {
        let now = Date()
        if let lastPurge = lastPurgeDate, now.timeIntervalSince(lastPurge) < Self.purgeInterval {
            return
        }
        lastPurgeDate = now

        await purgeExpiredRecords()
    }

    /// Force purge of expired records (for testing or manual cleanup)
    func purgeExpiredRecords() async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -Self.retentionDays, to: Date()) ?? Date()

        let deletedCount = await MainActor.run { () -> Int in
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<AuditEventRecord>(
                predicate: #Predicate { $0.timestamp < cutoffDate }
            )

            let expiredRecords: [AuditEventRecord]
            do {
                expiredRecords = try context.fetch(descriptor)
            } catch {
                AppLoggers.audit.error("Failed to fetch expired audit records: \(error.localizedDescription, privacy: .public)")
                return 0
            }

            let count = expiredRecords.count
            for record in expiredRecords {
                context.delete(record)
            }

            do {
                try context.save()
            } catch {
                AppLoggers.audit.error("Failed to delete expired audit records: \(error.localizedDescription, privacy: .public)")
                return 0
            }

            return count
        }

        if deletedCount > 0 {
            AppLoggers.audit.info("Purged \(deletedCount, privacy: .public) expired audit records older than \(Self.retentionDays, privacy: .public) days")
        }
    }
}
