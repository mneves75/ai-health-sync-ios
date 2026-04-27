// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import HealthKit
import Testing
@testable import iOS_Health_Sync_App

struct MockHealthStore: HealthStoreProtocol {
    var requestedReadTypes: Set<HKObjectType> = []
    var authorizationStatusMap: [HKObjectType: HKAuthorizationStatus] = [:]
    var authorizationRequestStatus: HKAuthorizationRequestStatus = .shouldRequest

    func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping @Sendable (Bool, Error?) -> Void) {
        completion(true, nil)
    }

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        authorizationStatusMap[type] ?? .notDetermined
    }

    func getRequestStatusForAuthorization(toShare typesToShare: Set<HKSampleType>, read typesToRead: Set<HKObjectType>, completion: @escaping @Sendable (HKAuthorizationRequestStatus, Error?) -> Void) {
        completion(authorizationRequestStatus, nil)
    }

    func executeSampleQuery(sampleType: HKSampleType, predicate: NSPredicate, limit: Int, sortDescriptors: [NSSortDescriptor], completion: @escaping @Sendable ([HKSample]?, Error?) -> Void) {
        completion([], nil)
    }

    func execute(_ query: HKQuery) {
        // No-op in tests — route queries are exercised separately
    }
}

@Test
func healthSampleMapperMapsQuantitySample() {
    let quantityType = HKQuantityType(.stepCount)
    let quantity = HKQuantity(unit: .count(), doubleValue: 42)
    let start = Date().addingTimeInterval(-60)
    let end = Date()
    let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: start, end: end)
    let dto = HealthSampleMapper.mapSample(sample, requestedType: .steps)
    #expect(dto?.value == 42)
    #expect(dto?.unit == "count")
}

@Test
func healthKitServiceReturnsOkWithEmptyResultsWhenNoData() async {
    // NOTE: For READ-only permissions, we cannot check if authorization was granted.
    // Apple hides this for privacy reasons. We just try to fetch - if no permission
    // or no data, we get empty results. This is the correct Apple-recommended behavior.
    let service = HealthKitService(store: MockHealthStore())
    let response = await service.fetchSamples(types: [.steps], startDate: Date().addingTimeInterval(-3600), endDate: Date(), limit: 1000, offset: 0)
    #expect(response.status == .ok)
    #expect(response.samples.isEmpty)
    #expect(response.returnedCount == 0)
}

@Test
func appInfoPlistUsesApplicationBundlePackageType() throws {
    let testsDirURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    let plistURL = testsDirURL
        .deletingLastPathComponent()
        .appendingPathComponent("Config")
        .appendingPathComponent("Info.plist")

    let plistData = try Data(contentsOf: plistURL)
    let plistObject = try PropertyListSerialization.propertyList(from: plistData, format: nil)
    let plist = try #require(plistObject as? [String: Any], "Info.plist must decode into a dictionary")

    #expect(plist["CFBundlePackageType"] as? String == "APPL")
}

// MARK: - HealthSampleMapper — new type coverage Tests

@Test("Maps category sample for irregularHeartRhythmEvent with unit 'category' and raw integer value")
func healthSampleMapperMapsCategorySampleForIrregularHeartRhythmEvent() {
    let categoryType = HKObjectType.categoryType(forIdentifier: .irregularHeartRhythmEvent)!
    let start = Date().addingTimeInterval(-60)
    let end = Date()
    let sample = HKCategorySample(
        type: categoryType,
        value: HKCategoryValue.notApplicable.rawValue,
        start: start,
        end: end
    )
    let dto = HealthSampleMapper.mapSample(sample, requestedType: .irregularHeartRhythmEvent)
    #expect(dto != nil)
    #expect(dto?.unit == "category")
    #expect(dto?.value == Double(HKCategoryValue.notApplicable.rawValue))
    #expect(dto?.type == HealthDataType.irregularHeartRhythmEvent.rawValue)
}

@Test("Maps quantity sample for bloodGlucose with unit containing dL")
func healthSampleMapperMapsBloodGlucoseSample() {
    let quantityType = HKQuantityType(.bloodGlucose)
    let start = Date().addingTimeInterval(-60)
    let end = Date()
    let quantity = HKQuantity(unit: HKUnit(from: "mg/dL"), doubleValue: 95.0)
    let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: start, end: end)
    let dto = HealthSampleMapper.mapSample(sample, requestedType: .bloodGlucose)
    #expect(dto != nil)
    #expect(dto?.unit.contains("dL") == true)
    #expect(dto?.value == 95.0)
}

@Test("Maps quantity sample for cyclingFunctionalThresholdPower with watt unit")
func healthSampleMapperMapsCyclingFTPSample() {
    let quantityType = HKQuantityType(.cyclingFunctionalThresholdPower)
    let start = Date().addingTimeInterval(-60)
    let end = Date()
    let quantity = HKQuantity(unit: .watt(), doubleValue: 250.0)
    let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: start, end: end)
    let dto = HealthSampleMapper.mapSample(sample, requestedType: .cyclingFunctionalThresholdPower)
    #expect(dto != nil)
    // HKUnit.watt().unitString == "W"
    let unitString = dto!.unit.lowercased()
    #expect(unitString == "w" || unitString.contains("watt"))
    #expect(dto?.value == 250.0)
}

@Test("unitForQuantityType returns seconds for heartRateVariability")
func heartRateVariabilityUnitIsSecond() {
    let unit = HealthSampleMapper.unitForQuantityType(.heartRateVariability)
    // HRV (SDNN) is stored as seconds in HealthKit
    #expect(unit == HKUnit.second())
}

@Suite("matchesSleepType")
struct MatchesSleepTypeTests {
    private func makeSleepSample(value: HKCategoryValueSleepAnalysis) -> HKCategorySample {
        let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let start = Date().addingTimeInterval(-3600)
        let end = Date()
        return HKCategorySample(type: type, value: value.rawValue, start: start, end: end)
    }

    @Test("sleepAnalysis matches all sleep category values")
    func sleepAnalysisMatchesAll() {
        let allValues: [HKCategoryValueSleepAnalysis] = [
            .inBed, .asleepUnspecified, .awake, .asleepREM, .asleepCore, .asleepDeep
        ]
        for value in allValues {
            let sample = makeSleepSample(value: value)
            #expect(HealthSampleMapper.matchesSleepType(.sleepAnalysis, categorySample: sample))
        }
    }

    @Test("sleepInBed matches only inBed")
    func sleepInBedMatchesOnlyInBed() {
        #expect(HealthSampleMapper.matchesSleepType(.sleepInBed, categorySample: makeSleepSample(value: .inBed)))
        #expect(!HealthSampleMapper.matchesSleepType(.sleepInBed, categorySample: makeSleepSample(value: .awake)))
        #expect(!HealthSampleMapper.matchesSleepType(.sleepInBed, categorySample: makeSleepSample(value: .asleepREM)))
    }

    @Test("sleepAsleep matches asleepUnspecified only")
    func sleepAsleepMatchesAsleepUnspecified() {
        #expect(HealthSampleMapper.matchesSleepType(.sleepAsleep, categorySample: makeSleepSample(value: .asleepUnspecified)))
        #expect(!HealthSampleMapper.matchesSleepType(.sleepAsleep, categorySample: makeSleepSample(value: .inBed)))
        #expect(!HealthSampleMapper.matchesSleepType(.sleepAsleep, categorySample: makeSleepSample(value: .asleepREM)))
    }

    @Test("sleepAwake matches awake only")
    func sleepAwakeMatchesAwake() {
        #expect(HealthSampleMapper.matchesSleepType(.sleepAwake, categorySample: makeSleepSample(value: .awake)))
        #expect(!HealthSampleMapper.matchesSleepType(.sleepAwake, categorySample: makeSleepSample(value: .asleepCore)))
        #expect(!HealthSampleMapper.matchesSleepType(.sleepAwake, categorySample: makeSleepSample(value: .inBed)))
    }

    @Test("sleepREM matches asleepREM only")
    func sleepREMMatchesAsleepREM() {
        #expect(HealthSampleMapper.matchesSleepType(.sleepREM, categorySample: makeSleepSample(value: .asleepREM)))
        #expect(!HealthSampleMapper.matchesSleepType(.sleepREM, categorySample: makeSleepSample(value: .asleepDeep)))
        #expect(!HealthSampleMapper.matchesSleepType(.sleepREM, categorySample: makeSleepSample(value: .awake)))
    }

    @Test("sleepCore matches asleepCore only")
    func sleepCoreMatchesAsleepCore() {
        #expect(HealthSampleMapper.matchesSleepType(.sleepCore, categorySample: makeSleepSample(value: .asleepCore)))
        #expect(!HealthSampleMapper.matchesSleepType(.sleepCore, categorySample: makeSleepSample(value: .asleepREM)))
        #expect(!HealthSampleMapper.matchesSleepType(.sleepCore, categorySample: makeSleepSample(value: .asleepDeep)))
    }

    @Test("sleepDeep matches asleepDeep only")
    func sleepDeepMatchesAsleepDeep() {
        #expect(HealthSampleMapper.matchesSleepType(.sleepDeep, categorySample: makeSleepSample(value: .asleepDeep)))
        #expect(!HealthSampleMapper.matchesSleepType(.sleepDeep, categorySample: makeSleepSample(value: .inBed)))
        #expect(!HealthSampleMapper.matchesSleepType(.sleepDeep, categorySample: makeSleepSample(value: .asleepCore)))
    }
}

// MARK: - HealthKitService — new types return ok with empty results

@Test("Fetching bloodGlucose returns ok status with empty results")
func healthKitServiceReturnsOkForBloodGlucose() async {
    let service = HealthKitService(store: MockHealthStore())
    let response = await service.fetchSamples(
        types: [.bloodGlucose],
        startDate: Date().addingTimeInterval(-3600),
        endDate: Date(),
        limit: 1000,
        offset: 0
    )
    #expect(response.status == .ok)
    #expect(response.samples.isEmpty)
    #expect(response.returnedCount == 0)
}

@Test("Fetching mindfulMinutes returns ok status with empty results")
func healthKitServiceReturnsOkForMindfulMinutes() async {
    let service = HealthKitService(store: MockHealthStore())
    let response = await service.fetchSamples(
        types: [.mindfulMinutes],
        startDate: Date().addingTimeInterval(-3600),
        endDate: Date(),
        limit: 1000,
        offset: 0
    )
    #expect(response.status == .ok)
    #expect(response.samples.isEmpty)
    #expect(response.returnedCount == 0)
}
