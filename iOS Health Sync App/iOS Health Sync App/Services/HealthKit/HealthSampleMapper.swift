// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

@preconcurrency import HealthKit
import Foundation

struct HealthSampleMapper {
    static func mapSample(_ sample: HKSample, requestedType: HealthDataType) -> HealthSampleDTO? {
        let sourceName = sample.sourceRevision.source.name
        if let quantitySample = sample as? HKQuantitySample {
            let unit = unitForQuantityType(requestedType)
            let value = quantitySample.quantity.doubleValue(for: unit)
            return HealthSampleDTO(
                id: quantitySample.uuid,
                type: requestedType.rawValue,
                value: value,
                unit: unit.unitString,
                startDate: quantitySample.startDate,
                endDate: quantitySample.endDate,
                sourceName: sourceName,
                metadata: nil
            )
        }

        if let categorySample = sample as? HKCategorySample {
            if requestedType.isCategorySleepType, !matchesSleepType(requestedType, categorySample: categorySample) {
                return nil
            }
            let metadata = sleepMetadata(for: categorySample)
            return HealthSampleDTO(
                id: categorySample.uuid,
                type: requestedType.rawValue,
                value: Double(categorySample.value),
                unit: "category",
                startDate: categorySample.startDate,
                endDate: categorySample.endDate,
                sourceName: sourceName,
                metadata: metadata
            )
        }

        if let workout = sample as? HKWorkout {
            var metadata: [String: String] = [
                "activityType": workout.workoutActivityType.name,
                "durationSeconds": String(format: "%.0f", workout.duration)
            ]
            if let energy = activeEnergyKilocalories(for: workout) {
                metadata["totalEnergyKilocalories"] = String(format: "%.2f", energy)
            }
            if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
                metadata["totalDistanceMeters"] = String(format: "%.2f", distance)
            }

            return HealthSampleDTO(
                id: workout.uuid,
                type: HealthDataType.workouts.rawValue,
                value: workout.duration,
                unit: "s",
                startDate: workout.startDate,
                endDate: workout.endDate,
                sourceName: sourceName,
                metadata: metadata
            )
        }

        return nil
    }

    static func matchesSleepType(_ requested: HealthDataType, categorySample: HKCategorySample) -> Bool {
        guard let category = HKCategoryValueSleepAnalysis(rawValue: categorySample.value) else { return false }
        switch requested {
        case .sleepAnalysis:
            return true
        case .sleepInBed:
            return category == .inBed
        case .sleepAsleep:
            return category == .asleepUnspecified
        case .sleepAwake:
            return category == .awake
        case .sleepREM:
            return category == .asleepREM
        case .sleepCore:
            return category == .asleepCore
        case .sleepDeep:
            return category == .asleepDeep
        default:
            return true
        }
    }

    static func unitForQuantityType(_ type: HealthDataType) -> HKUnit {
        switch type {
        case .steps, .standHours, .flightsClimbed:
            return .count()
        case .distanceWalkingRunning, .distanceCycling:
            return .meter()
        case .activeEnergyBurned, .basalEnergyBurned:
            return .kilocalorie()
        case .exerciseTime:
            return .minute()
        case .heartRate, .restingHeartRate, .walkingHeartRateAverage:
            return .count().unitDivided(by: .minute())
        case .heartRateVariability:
            return .second()
        case .bloodPressureSystolic, .bloodPressureDiastolic:
            return .millimeterOfMercury()
        case .bloodOxygen:
            return .percent()
        case .respiratoryRate:
            return .count().unitDivided(by: .minute())
        case .bodyTemperature:
            return .degreeCelsius()
        case .vo2Max:
            return HKUnit(from: "ml/kg*min")
        case .weight:
            return .gramUnit(with: .kilo)
        case .height:
            return .meter()
        case .bodyMassIndex:
            return .count()
        case .bodyFatPercentage:
            return .percent()
        case .leanBodyMass:
            return .gramUnit(with: .kilo)
        case .sleepAnalysis, .sleepInBed, .sleepAsleep, .sleepAwake, .sleepREM, .sleepCore, .sleepDeep, .workouts:
            return .count()
        }
    }

    static func sleepMetadata(for sample: HKCategorySample) -> [String: String]? {
        guard let category = HKCategoryValueSleepAnalysis(rawValue: sample.value) else {
            return nil
        }
        let stage: String
        switch category {
        case .inBed: stage = "inBed"
        case .asleepUnspecified: stage = "asleep"
        case .awake: stage = "awake"
        case .asleepREM: stage = "rem"
        case .asleepCore: stage = "core"
        case .asleepDeep: stage = "deep"
        @unknown default: stage = "unknown"
        }
        return ["sleepStage": stage]
    }

    private static func activeEnergyKilocalories(for workout: HKWorkout) -> Double? {
        if #available(iOS 18.0, *) {
            let quantityType = HKQuantityType(.activeEnergyBurned)
            if let stats = workout.statistics(for: quantityType), let quantity = stats.sumQuantity() {
                return quantity.doubleValue(for: .kilocalorie())
            }
            return nil
        } else {
            return workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
        }
    }
}

private extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "running"
        case .walking: return "walking"
        case .cycling: return "cycling"
        case .swimming: return "swimming"
        case .yoga: return "yoga"
        default: return "other"
        }
    }
}
