// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import HealthKit
import Foundation
import os

protocol HealthDataProviding: Sendable {
    func fetchSamples(types: [HealthDataType], startDate: Date, endDate: Date, limit: Int, offset: Int) async -> HealthDataResponse
}

actor HealthKitService {
    private let store: HealthStoreProtocol

    init(store: HealthStoreProtocol = HKHealthStore()) {
        self.store = store
    }

    func isAvailable() -> Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization(for types: [HealthDataType]) async throws -> Bool {
        let readTypes = Set(await MainActor.run { types.compactMap { $0.sampleType } })
        return try await withCheckedThrowingContinuation { continuation in
            store.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: success)
            }
        }
    }

    /// NOTE: authorizationStatus only works for WRITE permissions.
    /// For READ-only permissions (which we use), Apple intentionally hides
    /// whether the user granted or denied access for privacy reasons.
    /// This method is kept for compatibility but should not be used to determine read access.
    func authorizationStatus(for type: HealthDataType) async -> HKAuthorizationStatus {
        let sampleType = await MainActor.run { type.sampleType }
        guard let sampleType else { return .notDetermined }
        return store.authorizationStatus(for: sampleType)
    }

    /// Checks if we need to request authorization for the given types.
    /// Returns true if authorization has already been requested (user saw the dialog).
    /// NOTE: This does NOT tell us if the user granted or denied - that's private by design.
    func hasRequestedAuthorization(for types: [HealthDataType]) async -> Bool {
        let readTypes = Set(await MainActor.run { types.compactMap { $0.sampleType as? HKObjectType } })
        guard !readTypes.isEmpty else { return false }

        return await withCheckedContinuation { continuation in
            store.getRequestStatusForAuthorization(toShare: [], read: readTypes) { status, error in
                if let error {
                    AppLoggers.health.error("Failed to check authorization status: \(error.localizedDescription, privacy: .public)")
                    continuation.resume(returning: false)
                    return
                }
                // .unnecessary means we've already requested (user saw the dialog)
                // .shouldRequest means we haven't asked yet
                continuation.resume(returning: status == .unnecessary)
            }
        }
    }

    /// Maximum samples per request to prevent memory exhaustion
    private static let maxSamplesPerRequest = 10_000

    func fetchSamples(types: [HealthDataType], startDate: Date, endDate: Date, limit: Int, offset: Int) async -> HealthDataResponse {
        guard isAvailable() else {
            return HealthDataResponse(status: .error, samples: [], message: "Health data is unavailable on this device.", hasMore: false, returnedCount: 0)
        }

        let requestedTypes = await MainActor.run { types.compactMap { $0.sampleType } }
        guard !requestedTypes.isEmpty else {
            return HealthDataResponse(status: .error, samples: [], message: "No valid health data types were requested.", hasMore: false, returnedCount: 0)
        }

        // NOTE: We intentionally DO NOT check authorizationStatus here.
        // For READ-only permissions, Apple hides whether access was granted for privacy.
        // authorizationStatus only works for WRITE permissions.
        // Instead, we just try to fetch - if no permission, query returns empty results.
        // This is the Apple-recommended approach for read-only health apps.

        // Cap the limit to prevent memory exhaustion
        let effectiveLimit = min(limit, Self.maxSamplesPerRequest)

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        var collected: [HealthSampleDTO] = []
        for type in types {
            let sampleType = await MainActor.run { type.sampleType }
            guard let sampleType else { continue }
            // Fetch one more than needed to detect if there are more samples
            let samples = await querySamples(for: type, sampleType: sampleType, predicate: predicate, limit: effectiveLimit + offset + 1)
            collected.append(contentsOf: samples)
        }

        // Sort all collected samples by date (descending)
        let sorted = collected.sorted { $0.startDate > $1.startDate }

        // Apply offset and limit
        let afterOffset = Array(sorted.dropFirst(offset))
        let hasMore = afterOffset.count > effectiveLimit
        let paginated = Array(afterOffset.prefix(effectiveLimit))

        // If we got no samples, it could mean:
        // 1. User denied permission (we can't know this)
        // 2. User has no health data in the date range
        // 3. User granted permission but hasn't recorded data
        // We return .ok with empty results - the UI can inform the user
        return HealthDataResponse(status: .ok, samples: paginated, message: nil, hasMore: hasMore, returnedCount: paginated.count)
    }

    private func querySamples(for type: HealthDataType, sampleType: HKSampleType, predicate: NSPredicate, limit: Int) async -> [HealthSampleDTO] {
        await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            store.executeSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: [sort]) { results, error in
                if let error {
                    AppLoggers.health.error("HealthKit query failed: \(error.localizedDescription, privacy: .public)")
                    continuation.resume(returning: [])
                    return
                }

                let samples = results?.compactMap { sample in
                    HealthSampleMapper.mapSample(sample, requestedType: type)
                } ?? []

                continuation.resume(returning: samples)
            }
        }
    }

}

extension HealthKitService: HealthDataProviding {}

private extension Sequence {
    func asyncFilter(_ isIncluded: @escaping (Element) async -> Bool) async -> [Element] {
        var results: [Element] = []
        for element in self {
            if await isIncluded(element) {
                results.append(element)
            }
        }
        return results
    }
}
