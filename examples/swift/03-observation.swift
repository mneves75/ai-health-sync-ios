#!/usr/bin/env swift -parse-as-library
// Example 3: SwiftUI @Observation Framework
//
// This example demonstrates Swift 6's @Observation macro for state management.
// This replaces ObservableObject and is more efficient.
// Run it with: swift 03-observation.swift
//
// Prerequisites: Swift 5.9+ (included with Xcode 15+)

import Foundation
import Observation

// MARK: - 1. Observable Macro

/// An observable class using @Observable macro
/// This is the modern way to manage state in SwiftUI (iOS 17+)
@Observable
class HealthSettings {
    var stepsGoal: Int = 10_000
    var isHeartRateEnabled: Bool = true
    var isSleepEnabled: Bool = false
    var syncInterval: TimeInterval = 300.0 // 5 minutes

    // Computed properties work automatically
    var hasGoals: Bool {
        return stepsGoal > 0
    }

    /// Reset to defaults
    func resetToDefaults() {
        stepsGoal = 10_000
        isHeartRateEnabled = true
        isSleepEnabled = false
        syncInterval = 300.0
    }

    /// Enable all health types
    func enableAll() {
        isHeartRateEnabled = true
        isSleepEnabled = true
    }
}

// MARK: - 2. Observable with Dependencies

@Observable
class DeviceConnection {
    private(set) var isConnected: Bool = false
    private(set) var connectionTime: Date?
    private(set) var lastError: String?

    func connect() async {
        print("  🔄 Connecting to device...")

        // Simulate connection attempt
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        isConnected = Bool.random()
        if isConnected {
            connectionTime = Date()
            lastError = nil
            print("  ✅ Connected!")
        } else {
            lastError = "Connection timeout"
            print("  ❌ Connection failed")
        }
    }

    func disconnect() {
        isConnected = false
        connectionTime = nil
        print("  🔌 Disconnected")
    }
}

// MARK: - 3. Manual Change Tracking

/// Example of manual change tracking with @Observation
@Observable
class DataSyncManager {
    var syncProgress: Double = 0.0
    var isSyncing: Bool = false
    var lastSyncDate: Date?

    // You can manually notify observers if needed
    func startSync() {
        isSyncing = true
        syncProgress = 0.0
        print("  🔄 Starting sync...")

        // Simulate sync progress
        Task {
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                syncProgress = Double(i) / 10.0
                print("    Progress: \(Int(syncProgress * 100))%")
            }

            isSyncing = false
            lastSyncDate = Date()
            print("  ✅ Sync complete!")
        }
    }
}

// MARK: - 4. Main Execution

@main
struct ObservationExample {
    static func main() async {
        print("=== SwiftUI @Observation Framework Examples ===\n")

        // Example 1: Basic observable
        print("1. Basic Observable HealthSettings:")
        let settings = HealthSettings()

        print("  Initial settings:")
        print("    Steps goal: \(settings.stepsGoal)")
        print("    Heart rate: \(settings.isHeartRateEnabled)")
        print("    Sleep: \(settings.isSleepEnabled)")
        print("    Has goals: \(settings.hasGoals)")

        // Modify settings
        settings.stepsGoal = 15_000
        settings.isSleepEnabled = true
        print("\n  Modified settings:")
        print("    Steps goal: \(settings.stepsGoal)")
        print("    Sleep: \(settings.isSleepEnabled)")
        print()

        // Example 2: Observable with async operations
        print("2. Device Connection with @Observable:")
        let connection = DeviceConnection()

        // Simulate multiple connection attempts
        for i in 1...3 {
            print("  Attempt \(i):")
            await connection.connect()

            if connection.isConnected {
                print("    Connected at: \(connection.connectionTime!)")
                connection.disconnect()
                break
            } else {
                print("    Error: \(connection.lastError!)")
            }
        }
        print()

        // Example 3: Data sync with progress tracking
        print("3. Data Sync Manager:")
        let syncManager = DataSyncManager()

        syncManager.startSync()

        // Wait for sync to complete
        try? await Task.sleep(nanoseconds: 3_000_000_000)

        if let lastSync = syncManager.lastSyncDate {
            print("  Last sync: \(lastSync)")
        }
        print()

        print("✅ All examples completed!")
        print("\nKey Takeaways:")
        print("  • @Observable is the modern replacement for ObservableObject")
        print("  • All properties automatically notify observers on change")
        print("  • No need for @Published - it's automatic")
        print("  • Computed properties work without special syntax")
        print("  • More efficient than ObservableObject (fine-grained tracking)")
        print("  • Works seamlessly with SwiftUI views")
    }
}
