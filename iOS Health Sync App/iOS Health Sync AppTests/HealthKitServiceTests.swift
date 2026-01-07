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
