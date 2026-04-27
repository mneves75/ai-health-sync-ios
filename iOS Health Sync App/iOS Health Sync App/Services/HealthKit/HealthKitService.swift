// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import HealthKit
import Foundation
import os

protocol HealthDataProviding: Sendable {
    func fetchSamples(types: [HealthDataType], startDate: Date, endDate: Date, limit: Int, offset: Int) async -> HealthDataResponse
    func fetchECG(startDate: Date, endDate: Date) async -> ECGResponse
    func fetchHRVSeries(startDate: Date, endDate: Date) async -> HRVSeriesResponse
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
        var readTypes = Set(await MainActor.run { types.compactMap { $0.sampleType as HKObjectType? } })
        // Include Watch-exclusive series types alongside sample types
        if #available(iOS 14.0, *) {
            readTypes.insert(HKObjectType.electrocardiogramType())
        }
        readTypes.insert(HKSeriesType.heartbeat())
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
        let readTypes = Set(await MainActor.run { types.compactMap { type in if let st = type.sampleType { return st as HKObjectType } else { return nil } } })
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

extension HealthKitService: HealthDataProviding {
    // MARK: - ECG (Apple Watch exclusive, iOS 14+)

    /// Max ECG readings per request — ECGs are rare (typically <5/day during anomalies).
    private static let maxECGReadings = 50

    func fetchECG(startDate: Date, endDate: Date) async -> ECGResponse {
        guard isAvailable() else {
            return ECGResponse(status: .error, readings: [], message: "Health data unavailable on this device.", truncated: false)
        }
        guard #available(iOS 14.0, *) else {
            return ECGResponse(status: .error, readings: [], message: "ECG requires iOS 14 or later.", truncated: false)
        }

        let ecgType = HKObjectType.electrocardiogramType()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let rawSamples: [HKElectrocardiogram] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: ecgType, predicate: predicate, limit: Self.maxECGReadings + 1, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    AppLoggers.health.error("ECG sample query failed: \(error.localizedDescription, privacy: .public)")
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: (samples as? [HKElectrocardiogram]) ?? [])
            }
            store.execute(query)
        }

        let truncated = rawSamples.count > Self.maxECGReadings
        let toProcess = Array(rawSamples.prefix(Self.maxECGReadings))

        var readings: [ECGReading] = []
        for ecg in toProcess {
            let reading = await fetchECGReading(ecg)
            readings.append(reading)
        }

        return ECGResponse(status: .ok, readings: readings, message: nil, truncated: truncated)
    }

    @available(iOS 14.0, *)
    private func fetchECGReading(_ ecg: HKElectrocardiogram) async -> ECGReading {
        let voltageSamples: [ECGVoltageSample] = await withCheckedContinuation { continuation in
            var collected: [ECGVoltageSample] = []
            let voltageQuery = HKElectrocardiogramQuery(ecg) { _, result in
                switch result {
                case .measurement(let measurement):
                    if let voltage = measurement.quantity(for: .appleWatchSimilarToLeadI) {
                        let mv = voltage.doubleValue(for: HKUnit.volt().unitMultiplied(by: HKUnit.init(from: "1e3")))
                        collected.append(ECGVoltageSample(
                            timeSinceStartSeconds: measurement.timeSinceSampleStart,
                            voltageMillivolts: mv
                        ))
                    }
                case .done(let error):
                    if let error {
                        AppLoggers.health.error("ECG voltage query failed: \(error.localizedDescription, privacy: .public)")
                    }
                    continuation.resume(returning: collected)
                @unknown default:
                    break
                }
            }
            store.execute(voltageQuery)
        }

        let hrBPM: Double?
        if let hrQuantity = ecg.averageHeartRate {
            hrBPM = hrQuantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        } else {
            hrBPM = nil
        }

        let freqHz: Double?
        if let freq = ecg.samplingFrequency {
            freqHz = freq.doubleValue(for: .hertz())
        } else {
            freqHz = nil
        }

        return ECGReading(
            id: ecg.uuid,
            startDate: ecg.startDate,
            endDate: ecg.endDate,
            classification: ecg.classification.name,
            averageHeartRateBPM: hrBPM,
            samplingFrequencyHz: freqHz,
            numberOfMeasurements: ecg.numberOfVoltageMeasurements,
            symptomsPresent: ecg.symptomsStatus == .present,
            voltageSamples: voltageSamples
        )
    }

    // MARK: - HRV Series (per-beat R-R intervals)

    /// Max heartbeat series samples per request.
    private static let maxHRVSeries = 100
    /// Max R-R intervals per series sample to prevent memory exhaustion.
    private static let maxIntervalsPerSeries = 10_000

    func fetchHRVSeries(startDate: Date, endDate: Date) async -> HRVSeriesResponse {
        guard isAvailable() else {
            return HRVSeriesResponse(status: .error, series: [], message: "Health data unavailable on this device.", truncated: false)
        }

        let seriesType = HKSeriesType.heartbeat()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let rawSamples: [HKHeartbeatSeriesSample] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: seriesType, predicate: predicate, limit: Self.maxHRVSeries + 1, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    AppLoggers.health.error("HRV series query failed: \(error.localizedDescription, privacy: .public)")
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: (samples as? [HKHeartbeatSeriesSample]) ?? [])
            }
            store.execute(query)
        }

        let truncated = rawSamples.count > Self.maxHRVSeries
        let toProcess = Array(rawSamples.prefix(Self.maxHRVSeries))

        var seriesList: [HRVSeries] = []
        for sample in toProcess {
            if let series = await fetchHRVIntervals(sample) {
                seriesList.append(series)
            }
        }

        return HRVSeriesResponse(status: .ok, series: seriesList, message: nil, truncated: truncated)
    }

    private func fetchHRVIntervals(_ sample: HKHeartbeatSeriesSample) async -> HRVSeries? {
        let intervals: [RRInterval] = await withCheckedContinuation { continuation in
            var collected: [RRInterval] = []
            var didResume = false
            let query = HKHeartbeatSeriesQuery(heartbeatSeries: sample) { _, timeSinceStart, precededByGap, done, error in
                if let error {
                    AppLoggers.health.error("HRV interval query failed: \(error.localizedDescription, privacy: .public)")
                    if !didResume {
                        didResume = true
                        continuation.resume(returning: collected)
                    }
                    return
                }
                if collected.count < Self.maxIntervalsPerSeries {
                    collected.append(RRInterval(
                        timeSinceStartSeconds: timeSinceStart,
                        intervalSeconds: timeSinceStart - (collected.last?.timeSinceStartSeconds ?? 0),
                        isPrecededByABeat: !precededByGap
                    ))
                }
                if done && !didResume {
                    didResume = true
                    continuation.resume(returning: collected)
                }
            }
            store.execute(query)
        }

        guard !intervals.isEmpty else { return nil }

        return HRVSeries(
            id: sample.uuid,
            startDate: sample.startDate,
            endDate: sample.endDate,
            intervals: intervals,
            sdnnMilliseconds: computeSDNN(intervals),
            rmssdMilliseconds: computeRMSSD(intervals)
        )
    }

    private func computeSDNN(_ intervals: [RRInterval]) -> Double? {
        let rrSeconds = intervals.map { $0.intervalSeconds }
        guard rrSeconds.count > 1 else { return nil }
        let mean = rrSeconds.reduce(0, +) / Double(rrSeconds.count)
        let variance = rrSeconds.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(rrSeconds.count)
        return sqrt(variance) * 1000
    }

    private func computeRMSSD(_ intervals: [RRInterval]) -> Double? {
        let rrSeconds = intervals.map { $0.intervalSeconds }
        guard rrSeconds.count > 1 else { return nil }
        let squaredDiffs = zip(rrSeconds, rrSeconds.dropFirst()).map { ($1 - $0) * ($1 - $0) }
        let mean = squaredDiffs.reduce(0, +) / Double(squaredDiffs.count)
        return sqrt(mean) * 1000
    }
}

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

@available(iOS 14.0, *)
private extension HKElectrocardiogram.Classification {
    var name: String {
        switch self {
        case .notSet: return "notSet"
        case .sinusRhythm: return "sinusRhythm"
        case .atrialFibrillation: return "atrialFibrillation"
        case .inconclusiveLowHeartRate: return "inconclusiveLowHeartRate"
        case .inconclusiveHighHeartRate: return "inconclusiveHighHeartRate"
        case .inconclusivePoorReading: return "inconclusivePoorReading"
        case .inconclusiveOther: return "inconclusiveOther"
        case .unrecognized: return "unrecognized"
        @unknown default: return "unknown"
        }
    }
}

