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
            let metadata = requestedType.isCategorySleepType ? sleepMetadata(for: categorySample) : nil
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
                "durationSeconds": String(format: "%.0f", workout.duration),
                "sourceApp": workout.sourceRevision.source.bundleIdentifier
            ]
            if let energy = activeEnergyKilocalories(for: workout) {
                metadata["totalEnergyKilocalories"] = String(format: "%.2f", energy)
            }
            if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
                metadata["totalDistanceMeters"] = String(format: "%.2f", distance)
                // Derive avg speed from distance + duration when statistics are absent
                if workout.duration > 0 {
                    metadata["avgSpeedMetersPerSec"] = String(format: "%.4f", distance / workout.duration)
                }
            }
            // Heart rate statistics (embedded by Apple Watch and some third-party apps)
            if let hrStats = workout.statistics(for: HKQuantityType(.heartRate)) {
                let bpm = HKUnit.count().unitDivided(by: .minute())
                if let min = hrStats.minimumQuantity()?.doubleValue(for: bpm) {
                    metadata["heartRateMin"] = String(format: "%.0f", min)
                }
                if let max = hrStats.maximumQuantity()?.doubleValue(for: bpm) {
                    metadata["heartRateMax"] = String(format: "%.0f", max)
                }
                if let avg = hrStats.averageQuantity()?.doubleValue(for: bpm) {
                    metadata["heartRateAvg"] = String(format: "%.1f", avg)
                }
            }
            // Elevation from workout metadata
            if let ascent = (workout.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity)?.doubleValue(for: .meter()) {
                metadata["elevationAscendedMeters"] = String(format: "%.1f", ascent)
            }
            if let descent = (workout.metadata?[HKMetadataKeyElevationDescended] as? HKQuantity)?.doubleValue(for: .meter()) {
                metadata["elevationDescendedMeters"] = String(format: "%.1f", descent)
            }
            // Indoor/outdoor flag
            if let indoorWorkout = workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool {
                metadata["isIndoor"] = indoorWorkout ? "true" : "false"
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
            // HealthKit stores SDNN in seconds; expose as milliseconds for usability
            return .secondUnit(with: .milli)
        case .bloodPressureSystolic, .bloodPressureDiastolic:
            return .millimeterOfMercury()
        case .bloodOxygen:
            return .percent()
        case .respiratoryRate:
            return .count().unitDivided(by: .minute())
        case .bodyTemperature, .wristTemperature:
            return .degreeCelsius()
        case .vo2Max:
            return HKUnit(from: "ml/kg*min")
        case .weight, .leanBodyMass:
            return .gramUnit(with: .kilo)
        case .height, .runningStrideLength, .walkingStepLength:
            return .meter()
        case .runningVerticalOscillation:
            // Store in centimetres — more readable than metres for ~8cm oscillation
            return .meterUnit(with: .centi)
        case .runningGroundContactTime:
            return .secondUnit(with: .milli)
        case .runningPower, .cyclingPower:
            return .watt()
        case .runningSpeed, .cyclingSpeed, .walkingSpeed:
            return .meter().unitDivided(by: .second())
        case .cyclingCadence:
            return .count().unitDivided(by: .minute())
        case .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage, .bodyFatPercentage, .atrialFibrillationBurden:
            return .percent()
        case .stairAscentSpeed, .stairDescentSpeed:
            return .meter().unitDivided(by: .second())
        case .timeInDaylight, .mindfulMinutes:
            return .minute()
        case .physicalEffort:
            return HKUnit(from: "kcal/hr·kg")
        case .bodyMassIndex:
            return .count()
        case .waistCircumference:
            return .meterUnit(with: .centi)
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
        case .elliptical: return "elliptical"
        case .rowing: return "rowing"
        case .hiking: return "hiking"
        case .climbing: return "climbing"
        case .skiing: return "skiing"
        case .snowboarding: return "snowboarding"
        case .soccer: return "soccer"
        case .basketball: return "basketball"
        case .tennis: return "tennis"
        case .tableTennis: return "tableTennis"
        case .badminton: return "badminton"
        case .volleyball: return "volleyball"
        case .gymnastics: return "gymnastics"
        case .dance: return "dance"
        case .pilates: return "pilates"
        case .flexibility: return "flexibility"
        case .functionalStrengthTraining: return "functionalStrength"
        case .traditionalStrengthTraining: return "strengthTraining"
        case .highIntensityIntervalTraining: return "hiit"
        case .crossTraining: return "crossTraining"
        case .jumpRope: return "jumpRope"
        case .stairClimbing: return "stairClimbing"
        case .coreTraining: return "coreTraining"
        case .mindAndBody: return "mindAndBody"
        case .boxing: return "boxing"
        case .martialArts: return "martialArts"
        case .golf: return "golf"
        case .curling: return "curling"
        case .cricket: return "cricket"
        case .rugby: return "rugby"
        case .americanFootball: return "americanFootball"
        case .baseball: return "baseball"
        case .softball: return "softball"
        case .handCycling: return "handCycling"
        case .wheelchairWalkPace: return "wheelchairWalk"
        case .wheelchairRunPace: return "wheelchairRun"
        case .waterFitness: return "waterFitness"
        case .waterPolo: return "waterPolo"
        case .waterSports: return "waterSports"
        case .surfingSports: return "surfing"
        case .snowSports: return "snowSports"
        case .swimBikeRun: return "triathlon"
        case .other: return "other"
        default: return "other"
        }
    }
}
