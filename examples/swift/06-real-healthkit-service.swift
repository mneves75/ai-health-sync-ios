#!/usr/bin/env swift -parse-as-library
// Example 6: Real HealthKitService from iOS Health Sync App
//
// ⚠️ IMPORTANT: This example shows PATTERNS from the real app code
// but cannot compile standalone because it depends on HealthKit.
//
// This file demonstrates:
// - Actor isolation for thread safety
// - Async/await for callback-based APIs
// - Privacy-first authorization handling
// - Pagination and memory management
// - Real error handling patterns
//
// For WORKING examples, see examples 01-05 which are self-contained.
//
// To see the ACTUAL working code, open:
// iOS Health Sync App/iOS Health Sync App/Services/HealthKit/HealthKitService.swift

import Foundation

// MARK: - 1. Protocol for Testability

/// Protocol for HealthKit data fetching - enables testing with mocks
protocol HealthDataProviding: Sendable {
    func fetchSamples(
        types: [HealthDataType],
        startDate: Date,
        endDate: Date,
        limit: Int,
        offset: Int
    ) async -> HealthDataResponse
}

// MARK: - 2. Main Actor-Based Service

/// Manages all HealthKit data access with actor-based thread safety.
/// This is the REAL implementation from iOS Health Sync.
actor HealthKitService {
    // MARK: - Properties

    /// The underlying HealthKit store (wrapped for testability)
    private let store: HealthStoreProtocol

    /// Maximum samples per request to prevent memory exhaustion
    /// Real-world lesson: HealthKit can return HUGE datasets
    private static let maxSamplesPerRequest = 10_000

    // MARK: - Initialization

    /// Initialize with a HealthKit store (or mock for testing)
    init(store: HealthStoreProtocol = HKHealthStore()) {
        self.store = store
    }

    // MARK: - 3. HealthKit Availability

    /// Check if HealthKit is available on this device
    func isAvailable() -> Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - 4. Authorization (Privacy-First)

    /// Request HealthKit authorization for specified data types.
    ///
    /// IMPORTANT: HealthKit authorization is one-time only.
    /// Once a user decides, they can only change it in Settings.
    ///
    /// Privacy note: We can NOT tell if user denied vs. just has no data.
    /// This is intentional Apple design for user privacy.
    func requestAuthorization(for types: [HealthDataType]) async throws -> Bool {
        // Convert our types to HKSampleType (must run on MainActor)
        let readTypes = Set(await MainActor.run { types.compactMap { $0.sampleType } })

        // Wrap callback-based HealthKit API in async/await
        return try await withCheckedThrowingContinuation { continuation in
            store.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: success)
            }
        }
    }

    /// Check if we've already asked for permission (not if they said yes)
    ///
    /// Returns: true if user saw the dialog (even if they denied)
    ///          false if we haven't asked yet
    func hasRequestedAuthorization(for types: [HealthDataType]) async -> Bool {
        let readTypes = Set(await MainActor.run { types.compactMap { $0.sampleType as? HKObjectType } })
        guard !readTypes.isEmpty else { return false }

        return await withCheckedContinuation { continuation in
            store.getRequestStatusForAuthorization(toShare: [], read: readTypes) { status, error in
                if let error = error {
                    AppLoggers.health.error("Failed to check authorization: \(error)")
                    continuation.resume(returning: false)
                    return
                }
                // .unnecessary = we already asked
                // .shouldRequest = we haven't asked yet
                continuation.resume(returning: status == .unnecessary)
            }
        }
    }

    // MARK: - 5. Fetching Health Data (Real Implementation)

    /// Fetch health samples from HealthKit.
    ///
    /// This is the CORE function that retrieves health data.
    /// It demonstrates:
    /// - Actor isolation (thread-safe by default)
    /// - Memory management (capping results)
    /// - Pagination (offset/limit)
    /// - Error resilience
    ///
    /// Real-world notes:
    /// - We DON'T check authorizationStatus - it doesn't work for read-only
    /// - We just try to fetch - empty results = no permission OR no data
    /// - This is Apple's recommended approach for privacy
    func fetchSamples(
        types: [HealthDataType],
        startDate: Date,
        endDate: Date,
        limit: Int,
        offset: Int
    ) async -> HealthDataResponse {
        // Guard: HealthKit available?
        guard isAvailable() else {
            return HealthDataResponse(
                status: .error,
                samples: [],
                message: "Health data is unavailable on this device.",
                hasMore: false,
                returnedCount: 0
            )
        }

        // Convert types to HKSampleType
        let requestedTypes = await MainActor.run { types.compactMap { $0.sampleType } }
        guard !requestedTypes.isEmpty else {
            return HealthDataResponse(
                status: .error,
                samples: [],
                message: "No valid health data types were requested.",
                hasMore: false,
                returnedCount: 0
            )
        }

        // Cap limit to prevent memory exhaustion
        let effectiveLimit = min(limit, Self.maxSamplesPerRequest)

        // Create date predicate for query
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        // Fetch samples for each type
        var collected: [HealthSampleDTO] = []
        for type in types {
            let sampleType = await MainActor.run { type.sampleType }
            guard let sampleType else { continue }

            // Fetch one extra to detect if there are more results
            let samples = await querySamples(
                for: type,
                sampleType: sampleType,
                predicate: predicate,
                limit: effectiveLimit + offset + 1
            )
            collected.append(contentsOf: samples)
        }

        // Sort by date (newest first)
        let sorted = collected.sorted { $0.startDate > $1.startDate }

        // Apply pagination
        let afterOffset = Array(sorted.dropFirst(offset))
        let hasMore = afterOffset.count > effectiveLimit
        let paginated = Array(afterOffset.prefix(effectiveLimit))

        return HealthDataResponse(
            status: .ok,
            samples: paginated,
            message: nil,
            hasMore: hasMore,
            returnedCount: paginated.count
        )
    }

    // MARK: - 6. Private Query Method

    /// Execute a HealthKit query and convert results to our DTOs
    private func querySamples(
        for type: HealthDataType,
        sampleType: HKSampleType,
        predicate: NSPredicate,
        limit: Int
    ) async -> [HealthSampleDTO] {
        await withCheckedContinuation { continuation in
            // Sort by date descending
            let sort = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: false
            )

            // Execute the query
            store.executeSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sort]
            ) { results, error in
                if let error = error {
                    AppLoggers.health.error("HealthKit query failed: \(error)")
                    continuation.resume(returning: [])
                    return
                }

                // Map HKSamples to our DTOs
                let samples = results?.compactMap { sample in
                    HealthSampleMapper.mapSample(sample, requestedType: type)
                } ?? []

                continuation.resume(returning: samples)
            }
        }
    }
}

// MARK: - 7. Conformance to Protocol

extension HealthKitService: HealthDataProviding {}

// MARK: - Supporting Types (Simplified for Example)

enum HealthDataType {
    case steps
    case heartRate
    case sleep

    var sampleType: HKSampleType? {
        // In real app: returns actual HKSampleType
        return nil
    }
}

struct HealthDataResponse {
    let status: Status
    let samples: [HealthSampleDTO]
    let message: String?
    let hasMore: Bool
    let returnedCount: Int

    enum Status {
        case ok
        case error
    }
}

struct HealthSampleDTO: Codable {
    let id: String
    let type: String
    let value: Double
    let unit: String
    let startDate: Date
    let endDate: Date
    let sourceName: String
}

// MARK: - Mock Types for Example

// NOTE: This is a SIMPLIFIED mock for demonstration purposes.
// The real HealthKit framework has complex protocols we can't fully replicate here.

// In the actual app, we use the real HKHealthStore which conforms to these protocols.
// This mock allows the example to compile without importing HealthKit.

protocol HealthStoreProtocol {
    // Simplified signatures - real HealthKit uses Sets which require Hashable conformance
    func requestAuthorization(toShare: [HKSampleType]?, read: [HKObjectType]?, completion: @escaping (Bool, Error?) -> Void)
    func getRequestStatusForAuthorization(toShare: [HKSampleType]?, read: [HKObjectType]?, completion: @escaping (HKAuthorizationRequestStatus, Error?) -> Void)
    func authorizationStatus(for: HKSampleType) -> HKAuthorizationStatus
    func executeSampleQuery(sampleType: HKSampleType, predicate: NSPredicate, limit: Int, sortDescriptors: [NSSortDescriptor], completion: @escaping ([HKSample]?, Error?) -> Void)
}

// Mock implementations (for compilation only - NOT functional!)
class HKHealthStore: HealthStoreProtocol {
    func requestAuthorization(toShare: [HKSampleType]?, read: [HKObjectType]?, completion: @escaping (Bool, Error?) -> Void) {
        // In real app, this shows the HealthKit authorization prompt
        completion(true, nil)
    }
    func getRequestStatusForAuthorization(toShare: [HKSampleType]?, read: [HKObjectType]?, completion: @escaping (HKAuthorizationRequestStatus, Error?) -> Void) {
        completion(.shouldRequest, nil)
    }
    func authorizationStatus(for: HKSampleType) -> HKAuthorizationStatus {
        return .notDetermined
    }
    func executeSampleQuery(sampleType: HKSampleType, predicate: NSPredicate, limit: Int, sortDescriptors: [NSSortDescriptor], completion: @escaping ([HKSample]?, Error?) -> Void) {
        completion([], nil)
    }
}

// Placeholder types for compilation
class HKSample {}
class HKSampleType {}
class HKObjectType {}
enum HKAuthorizationRequestStatus {
    case shouldRequest
    case unnecessary
}
enum HKAuthorizationStatus {
    case notDetermined
}
struct HKQuery {
    static func predicateForSamples(withStart: Date, end: Date, options: HKQueryOptions) -> NSPredicate {
        return NSPredicate()
    }
}
struct HKSampleSortIdentifier {
    static let startDate = "startDate"
}
enum HKQueryOptions {
    case strictStartDate
}

struct HealthSampleMapper {
    static func mapSample(_ sample: HKSample, requestedType: HealthDataType) -> HealthSampleDTO? {
        nil
    }
}

enum AppLoggers {
    static let health = OSLog(subsystem: "com.example", category: "Health")
}

struct OSLog {
    let subsystem: String
    let category: String

    func error(_ message: String) {
        print("[ERROR] \(message)")
    }
}

// MARK: - 8. Main Execution Example

@main
struct RealHealthKitExample {
    static func main() async {
        print("=== Real HealthKitService Example ===")
        print("")
        print("This example shows the ACTUAL HealthKitService from iOS Health Sync.")
        print("")

        // Create the service
        let service = HealthKitService()

        // Check availability
        print("1. HealthKit Available: \(service.isAvailable())")
        print("")

        // Check authorization status
        let types: [HealthDataType] = [.steps, .heartRate]
        let hasRequested = await service.hasRequestedAuthorization(for: types)
        print("2. Authorization Requested: \(hasRequested)")
        print("")

        // Fetch data (example)
        let now = Date()
        let yesterday = now.addingTimeInterval(-24 * 60 * 60)

        let response = await service.fetchSamples(
            types: types,
            startDate: yesterday,
            endDate: now,
            limit: 100,
            offset: 0
        )

        print("3. Fetch Results:")
        print("   Status: \(response.status)")
        print("   Count: \(response.returnedCount)")
        print("   Has More: \(response.hasMore)")
        print("")

        print("✅ Example Complete!")
        print("")
        print("Key Takeaways from Real Code:")
        print("  • Actors make HealthKit access thread-safe automatically")
        print("  • Async/await wraps callback-based APIs cleanly")
        print("  • Memory management caps prevent crashes")
        print("  • Privacy-first: we can't tell if user denied vs. no data")
        print("  • Protocol-based design enables testing")
        print("  • Pagination handles large datasets")
    }
}

// Note: This is a simplified version of the real code for clarity.
// The actual implementation has more error handling and logging.
