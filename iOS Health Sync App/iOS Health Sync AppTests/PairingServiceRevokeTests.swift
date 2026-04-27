// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import SwiftData
import Testing
@testable import iOS_Health_Sync_App

/// Pins the contract that `PairingService.revokeAll()` actually empties the
/// PairedDevice store rather than soft-deleting via `isActive = false`. The UI's
/// `@Query` returns all rows regardless of state, so soft-delete left revoked
/// devices visible in the Connected Macs section. This regression broke
/// `pairedDevices.isEmpty` checks in ContentView (Getting Started gating, type
/// picker visibility, toolbar presence). Hard delete also removes stale
/// `tokenHash` data from disk on data-minimization grounds.
@Suite("PairingService.revokeAll")
struct PairingServiceRevokeTests {
    @MainActor
    @Test
    func revokeAllEmptiesPairedDeviceStore() async throws {
        let schema = Schema([SyncConfiguration.self, PairedDevice.self, AuditEventRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let service = PairingService(modelContainer: container)

        // Insert two devices, one active, one already-soft-revoked from prior code path
        let context = container.mainContext
        context.insert(PairedDevice(
            name: "Living Room Mac",
            tokenHash: "abc",
            expiresAt: Date().addingTimeInterval(3600),
            isActive: true
        ))
        context.insert(PairedDevice(
            name: "Old Office Mac",
            tokenHash: "def",
            expiresAt: Date().addingTimeInterval(-3600),
            isActive: false
        ))
        try context.save()

        let beforeCount = try context.fetch(FetchDescriptor<PairedDevice>()).count
        #expect(beforeCount == 2, "Test setup precondition")

        await service.revokeAll()

        let afterCount = try context.fetch(FetchDescriptor<PairedDevice>()).count
        #expect(afterCount == 0, "revokeAll() must hard-delete all rows so @Query reactively reflects an empty paired list")
    }
}
