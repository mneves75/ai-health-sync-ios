// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

@preconcurrency import HealthKit

protocol HealthStoreProtocol {
    func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping @Sendable (Bool, Error?) -> Void)
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus
    func getRequestStatusForAuthorization(toShare typesToShare: Set<HKSampleType>, read typesToRead: Set<HKObjectType>, completion: @escaping @Sendable (HKAuthorizationRequestStatus, Error?) -> Void)
    func executeSampleQuery(sampleType: HKSampleType, predicate: NSPredicate, limit: Int, sortDescriptors: [NSSortDescriptor], completion: @escaping @Sendable ([HKSample]?, Error?) -> Void)
}

extension HKHealthStore: HealthStoreProtocol {
    func executeSampleQuery(sampleType: HKSampleType, predicate: NSPredicate, limit: Int, sortDescriptors: [NSSortDescriptor], completion: @escaping @Sendable ([HKSample]?, Error?) -> Void) {
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors) { _, samples, error in
            completion(samples, error)
        }
        execute(query)
    }
}
