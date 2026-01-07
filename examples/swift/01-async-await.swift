#!/usr/bin/env swift -parse-as-library
// Example 1: Swift 6 Async/Await Basics
//
// This example demonstrates Swift 6's modern concurrency model using async/await.
// Run it with: swift 01-async-await.swift
//
// Prerequisites: Swift 5.5+ (included with Xcode 13+)

import Foundation

// MARK: - 1. Basic Async Function

/// A simple async function that simulates fetching data
func fetchUserData() async -> String {
    print("📡 Fetching user data...")

    // Simulate network delay
    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

    return "John Doe"
}

// MARK: - 2. Async with Error Handling

enum NetworkError: Error {
    case invalidURL
    case serverError
}

func fetchHealthData() async throws -> [String] {
    print("📊 Fetching health data...")

    // Simulate network delay
    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

    // Simulate random success/failure
    let success = Bool.random()
    if !success {
        throw NetworkError.serverError
    }

    return ["Steps: 10,000", "Heart Rate: 72 bpm", "Sleep: 7.5 hours"]
}

// MARK: - 3. Structured Concurrency (Task Groups)

func fetchMultipleDataSources() async -> [String] {
    print("🔄 Fetching from multiple sources...")

    // TaskGroup allows running multiple async tasks concurrently
    return await withTaskGroup(of: String.self) { group in
        // Add tasks to the group
        group.addTask {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return "HealthKit data"
        }

        group.addTask {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            return "Activity data"
        }

        group.addTask {
            try? await Task.sleep(nanoseconds: 500_000_000)
            return "Location data"
        }

        // Collect results
        var results: [String] = []
        for await result in group {
            results.append(result)
            print("  ✓ Received: \(result)")
        }

        return results
    }
}

// MARK: - 4. Main Execution

@main
struct AsyncAwaitExample {
    static func main() async {
        print("=== Swift 6 Async/Await Examples ===\n")

        // Example 1: Basic async/await
        print("1. Basic Async Function:")
        let userName = await fetchUserData()
        print("   Result: \(userName)\n")

        // Example 2: Error handling
        print("2. Error Handling:")
        do {
            let healthData = try await fetchHealthData()
            print("   Success: \(healthData)")
        } catch NetworkError.serverError {
            print("   Error: Server error occurred")
        } catch {
            print("   Error: \(error)")
        }
        print()

        // Example 3: Task groups
        print("3. Structured Concurrency:")
        let allData = await fetchMultipleDataSources()
        print("   All results: \(allData)")
        print()

        print("✅ Examples completed!")
    }
}
