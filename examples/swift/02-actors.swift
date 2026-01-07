#!/usr/bin/env swift -parse-as-library
// Example 2: Swift 6 Actors for Thread Safety
//
// This example demonstrates Swift 6 actors, which provide data race safety
// by ensuring only one task can access actor-isolated state at a time.
// Run it with: swift 02-actors.swift
//
// Prerequisites: Swift 5.5+ (included with Xcode 13+)

import Foundation

// MARK: - 1. Basic Actor

/// A simple actor that manages a counter
actor BasicCounter {
    private var count = 0

    /// Actor-isolated method (safe from data races)
    func increment() -> Int {
        count += 1
        return count
    }

    /// Another actor-isolated method
    func getCount() -> Int {
        return count
    }

    /// Reset the counter
    func reset() {
        count = 0
    }
}

// MARK: - 2. Health Data Actor (Real-World Example)

/// Represents a single health sample
struct HealthSample: Sendable {
    let id: UUID
    let type: String
    let value: Double
    let timestamp: Date
}

/// Actor that manages health data (similar to HealthKitService in the app)
actor HealthDataManager {
    private var samples: [UUID: HealthSample] = [:]
    private var lastSync: Date?

    /// Add a new health sample
    func addSample(_ sample: HealthSample) {
        samples[sample.id] = sample
        print("  ✓ Added sample: \(sample.type) = \(sample.value)")
    }

    /// Get a specific sample by ID
    func getSample(id: UUID) -> HealthSample? {
        return samples[id]
    }

    /// Get all samples of a specific type
    func getSamplesByType(_ type: String) -> [HealthSample] {
        return samples.values.filter { $0.type == type }
    }

    /// Get the total count of samples
    func getSampleCount() -> Int {
        return samples.count
    }

    /// Update the last sync time
    func updateLastSync() {
        lastSync = Date()
    }

    /// Get last sync time (non-isolated, returns copy)
    func getLastSync() -> Date? {
        return lastSync
    }

    /// Clear all samples
    func clearAll() {
        samples.removeAll()
    }
}

// MARK: - 3. Bank Account Actor (Classic Example)

actor BankAccount {
    private(set) var balance: Double

    init(initialBalance: Double) {
        self.balance = initialBalance
    }

    /// Deposit money (thread-safe)
    func deposit(amount: Double) {
        balance += amount
        print("  💰 Deposited: $\(amount), New balance: $\(balance)")
    }

    /// Withdraw money (thread-safe)
    func withdraw(amount: Double) -> Bool {
        if balance >= amount {
            balance -= amount
            print("  💸 Withdrew: $\(amount), New balance: $\(balance)")
            return true
        } else {
            print("  ❌ Insufficient funds for withdrawal: $\(amount)")
            return false
        }
    }

    /// Get current balance (thread-safe read)
    func getBalance() -> Double {
        return balance
    }
}

// MARK: - 4. Main Execution

@main
struct ActorsExample {
    static func main() async {
        print("=== Swift 6 Actors Examples ===\n")

        // Example 1: Basic actor
        print("1. Basic Actor Counter:")
        let counter = BasicCounter()

        // Create multiple concurrent tasks that increment the counter
        await withTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask {
                    let value = await counter.increment()
                    print("  Task \(i): Count = \(value)")
                }
            }
        }

        let finalCount = await counter.getCount()
        print("  Final count: \(finalCount)")
        print()

        // Example 2: Health data manager
        print("2. Health Data Manager:")
        let healthManager = HealthDataManager()

        // Add multiple samples concurrently
        let sampleTypes = ["Steps", "Heart Rate", "Sleep", "Calories"]
        await withTaskGroup(of: Void.self) { group in
            for type in sampleTypes {
                group.addTask {
                    let sample = HealthSample(
                        id: UUID(),
                        type: type,
                        value: Double.random(in: 1...100),
                        timestamp: Date()
                    )
                    await healthManager.addSample(sample)
                }
            }
        }

        let count = await healthManager.getSampleCount()
        print("  Total samples: \(count)")

        // Query specific samples
        await healthManager.updateLastSync()
        if let syncTime = await healthManager.getLastSync() {
            print("  Last sync: \(syncTime)")
        }
        print()

        // Example 3: Bank account (thread-safe operations)
        print("3. Bank Account (Concurrent Operations):")
        let account = BankAccount(initialBalance: 1000.0)

        // Simulate concurrent deposits and withdrawals
        await withTaskGroup(of: Void.self) { group in
            // Deposits
            for amount in [100, 200, 50] {
                group.addTask {
                    await account.deposit(amount: amount)
                }
            }

            // Withdrawals
            for amount in [150, 300, 75] {
                group.addTask {
                    await account.withdraw(amount: amount)
                }
            }
        }

        let finalBalance = await account.getBalance()
        print("  Final balance: $\(finalBalance)")
        print()

        print("✅ All examples completed!")
        print("\nKey Takeaways:")
        print("  • Actors prevent data races by serializing access to their state")
        print("  • Only one task can access actor-isolated code at a time")
        print("  • Actors are perfect for managing shared mutable state")
        print("  • Use 'await' to call actor methods from outside the actor")
    }
}
