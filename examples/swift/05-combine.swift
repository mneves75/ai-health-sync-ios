#!/usr/bin/env swift -parse-as-library
// Example 5: Combine Framework for Reactive Programming
//
// This example demonstrates Combine, Apple's framework for reactive programming.
// Note: Combine is primarily for iOS/macOS apps, not command-line tools.
// This example shows the concepts, but in practice you'd use this in SwiftUI views.
//
// Run it with: swift 05-combine.swift
//
// Prerequisites: Swift 5.5+ (Combine is available on macOS 10.15+)

import Foundation
import Combine

// MARK: - 1. Simple Publisher

/// Create a simple publisher that emits values
func createSimplePublisher() -> AnyPublisher<String, Never> {
    return ["Hello", "Combine", "World"].publisher
        .eraseToAnyPublisher()
}

// MARK: - 2. Subject (Mutable Publisher)

/// A PassthroughSubject emits values to subscribers
class DataEmitter {
    let dataSubject = PassthroughSubject<String, Never>()

    func emit(value: String) {
        print("  📤 Emitting: \(value)")
        dataSubject.send(value)
    }

    func complete() {
        print("  ✅ Sending completion")
        dataSubject.send(completion: .finished)
    }
}

// MARK: - 3. CurrentValueSubject (Has Current Value)

/// CurrentValueSubject maintains the latest value
class SettingsStore {
    let syncEnabled = CurrentValueSubject<Bool, Never>(false)
    let syncInterval = CurrentValueSubject<Int, Never>(300)

    func toggleSync() {
        let newValue = !syncEnabled.value
        print("  🔄 Toggling sync: \(newValue)")
        syncEnabled.send(newValue)
    }

    func updateInterval(_ seconds: Int) {
        print("  ⏱️ Updating interval: \(seconds)s")
        syncInterval.send(seconds)
    }
}

// MARK: - 4. Network Request with Combine (Mock)

/// Simulate a network request using Combine
func fetchWithCombine() -> AnyPublisher<String, Error> {
    return Future<String, Error> { promise in
        print("  📡 Starting network request...")

        // Simulate network delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let success = Bool.random()

            if success {
                print("  ✅ Request succeeded")
                promise(.success("Data fetched successfully"))
            } else {
                print("  ❌ Request failed")
                promise(.failure(NetworkError.networkError(URLError(.notConnectedToInternet))))
            }
        }
    }
    .eraseToAnyPublisher()
}

// MARK: - 5. Debouncing User Input

/// Simulate a search bar that debounces user input
class SearchBar {
    let searchText = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Debounce search input (wait 0.5s after user stops typing)
        searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { text in
                print("  🔍 Searching for: '\(text)'")
            }
            .store(in: &cancellables)
    }

    func type(text: String) {
        searchText.send(text)
    }
}

// MARK: - 6. Combining Multiple Publishers

/// Combine multiple publishers and react to changes
class HealthMonitor {
    let stepsSubject = CurrentValueSubject<Int, Never>(0)
    let goalSubject = CurrentValueSubject<Int, Never>(10000)

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Combine steps and goal to calculate progress
        Publishers.CombineLatest(stepsSubject, goalSubject)
            .map { steps, goal in
                Double(steps) / Double(goal)
            }
            .sink { progress in
                let percentage = Int(progress * 100)
                print("  📊 Progress: \(percentage)%")
                if progress >= 1.0 {
                    print("  🎉 Goal reached!")
                }
            }
            .store(in: &cancellables)
    }

    func updateSteps(_ steps: Int) {
        print("  👟 Steps: \(steps)")
        stepsSubject.send(steps)
    }

    func updateGoal(_ goal: Int) {
        print("  🎯 Goal: \(goal)")
        goalSubject.send(goal)
    }
}

// MARK: - 7. Main Execution

@main
struct CombineExample {
    static func main() async {
        print("=== Combine Framework Examples ===\n")

        // Example 1: Simple publisher
        print("1. Simple Publisher:")
        let simplePublisher = createSimplePublisher()

        let cancellable1 = simplePublisher
            .sink { value in
                print("  Received: \(value)")
            }

        // Wait a bit for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        print()

        // Example 2: PassthroughSubject
        print("2. PassthroughSubject (Event Emitter):")
        let emitter = DataEmitter()

        let cancellable2 = emitter.dataSubject
            .sink { value in
                print("  📥 Subscriber received: \(value)")
            }

        emitter.emit(value: "First event")
        emitter.emit(value: "Second event")
        emitter.complete()

        try? await Task.sleep(nanoseconds: 100_000_000)
        print()

        // Example 3: CurrentValueSubject
        print("3. CurrentValueSubject (Settings Store):")
        let settings = SettingsStore()

        let cancellable3 = settings.syncEnabled
            .sink { enabled in
                print("  📢 Sync enabled changed to: \(enabled)")
            }

        settings.toggleSync()
        settings.toggleSync()

        try? await Task.sleep(nanoseconds: 100_000_000)
        print()

        // Example 4: Network request with Combine
        print("4. Network Request with Combine:")
        let cancellable4 = fetchWithCombine()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("  ✅ Completed")
                    case .failure(let error):
                        print("  ❌ Failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { value in
                    print("  📦 Received: \(value)")
                }
            )

        try? await Task.sleep(nanoseconds: 2_000_000_000)
        print()

        // Example 5: Debouncing
        print("5. Debounced Search Bar:")
        let searchBar = SearchBar()

        print("  User typing quickly:")
        searchBar.type(text: "s")
        try? await Task.sleep(nanoseconds: 100_000_000)
        searchBar.type(text: "sw")
        try? await Task.sleep(nanoseconds: 100_000_000)
        searchBar.type(text: "swi")
        try? await Task.sleep(nanoseconds: 100_000_000)
        searchBar.type(text: "swif")
        try? await Task.sleep(nanoseconds: 100_000_000)
        searchBar.type(text: "swift")
        try? await Task.sleep(nanoseconds: 600_000_000) // Wait for debounce

        print()

        // Example 6: Combining publishers
        print("6. Combining Multiple Publishers:")
        let monitor = HealthMonitor()

        monitor.updateSteps(5000)
        monitor.updateSteps(7500)
        monitor.updateSteps(10000)
        monitor.updateGoal(15000)
        monitor.updateSteps(12000)
        monitor.updateSteps(15000)

        try? await Task.sleep(nanoseconds: 100_000_000)
        print()

        print("✅ All examples completed!")
        print("\nKey Takeaways:")
        print("  • Publishers emit values over time")
        print("  • Subscribers receive and process those values")
        print("  • Operators (map, filter, debounce) transform streams")
        print("  • Subjects allow both publishing and subscribing")
        print("  • CombineLatest combines multiple publishers")
        print("  • Perfect for UI updates, data binding, async operations")
        print("  • In SwiftUI, @Observable often replaces Combine for state")
        print("  • Combine is still useful for networking and complex streams")
    }
}
