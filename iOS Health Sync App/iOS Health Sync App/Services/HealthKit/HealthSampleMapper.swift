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
            // value encodes the raw HKCategoryValue integer. For sleep types this is
            // HKCategoryValueSleepAnalysis (see sleepMetadata for the decoded stage string).
            // For cardiac events (irregularHeartRhythmEvent, highHeartRateEvent,
            // lowHeartRateEvent) it is HKCategoryValuePresence: 0 = notPresent, 1 = present.
            // For mindfulMinutes it is always HKCategoryValue.notApplicable (0).
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
        case .heartRateRecoveryOneMinute:
            return .count().unitDivided(by: .minute())
        case .bloodGlucose:
            return HKUnit(from: "mg/dL")
        case .peripheralPerfusionIndex:
            return .percent()
        case .distanceSwimming, .distanceDownhillSnowSports, .distanceWheelchair, .underwaterDepth:
            return .meter()
        case .swimmingStrokeCount, .pushCount, .numberOfTimesFallen, .numberOfAlcoholicBeverages:
            return .count()
        case .cyclingFunctionalThresholdPower:
            return .watt()
        case .waterTemperature:
            return .degreeCelsius()
        case .environmentalAudioExposure, .headphoneAudioExposure:
            return HKUnit(from: "dBASPL")
        case .irregularHeartRhythmEvent, .highHeartRateEvent, .lowHeartRateEvent:
            return .count()
        case .waistCircumference, .runningStrideLength, .runningVerticalOscillation, .walkingStepLength:
            return .meter()
        case .runningGroundContactTime:
            return .second()
        case .runningPower, .cyclingPower:
            return .watt()
        case .runningSpeed, .cyclingSpeed, .walkingSpeed, .stairAscentSpeed, .stairDescentSpeed:
            return .meter().unitDivided(by: .second())
        case .cyclingCadence:
            return .count().unitDivided(by: .minute())
        case .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage, .atrialFibrillationBurden:
            return .percent()
        case .wristTemperature:
            return .degreeCelsius()
        case .timeInDaylight:
            return .minute()
        case .physicalEffort:
            return HKUnit(from: "kcal/hr*kg")
        case .mindfulMinutes:
            // category type — routed via HKCategorySample path, not this function
            return .minute()

        // Nutrition — energy and water
        case .dietaryEnergyConsumed:
            return .kilocalorie()
        case .dietaryWater:
            return .literUnit(with: .milli)

        // Nutrition — macronutrients (grams)
        case .dietaryProtein, .dietaryFatTotal, .dietaryFatSaturated,
             .dietaryFatPolyunsaturated, .dietaryFatMonounsaturated,
             .dietaryCarbohydrates, .dietaryFiber, .dietarySugar:
            return .gram()

        // Nutrition — minerals/vitamins measured in milligrams
        case .dietaryCaffeine, .dietaryCholesterol, .dietarySodium, .dietaryCalcium,
             .dietaryIron, .dietaryMagnesium, .dietaryPotassium, .dietaryZinc,
             .dietaryPhosphorus, .dietaryCopper, .dietaryManganese, .dietaryChloride,
             .dietaryVitaminB6, .dietaryVitaminC, .dietaryVitaminE,
             .dietaryRiboflavin, .dietaryThiamin, .dietaryNiacin, .dietaryPantothenicAcid:
            return .gramUnit(with: .milli)

        // Nutrition — vitamins/minerals measured in micrograms
        case .dietaryIodine, .dietarySelenium, .dietaryChromium, .dietaryMolybdenum,
             .dietaryVitaminA, .dietaryVitaminB12, .dietaryVitaminD, .dietaryVitaminK,
             .dietaryFolate, .dietaryBiotin:
            return .gramUnit(with: .micro)

        // Spirometry
        case .forcedExpiratoryVolume1, .forcedVitalCapacity:
            return .liter()
        case .peakExpiratoryFlowRate:
            return .liter().unitDivided(by: .minute())
        case .inhalerUsage:
            return .count()
        case .insulinDelivery:
            return .internationalUnit()

        // Misc vital / lifestyle quantities
        case .basalBodyTemperature:
            return .degreeCelsius()
        case .bloodAlcoholContent:
            return .percent()
        case .electrodermalActivity:
            return .siemenUnit(with: .micro)
        case .environmentalSoundReduction:
            return HKUnit(from: "dBASPL")
        case .nikeFuel, .uvExposure:
            return .count()
        case .sixMinuteWalkTestDistance:
            return .meter()
        case .appleWalkingSteadiness:
            return .percent()
        case .appleMoveTime:
            return .minute()

        // Category types: routed via HKCategorySample path; values returned here are
        // never used at runtime but the switch must be exhaustive.
        case .abdominalCramps, .acne, .appetiteChanges, .bladderIncontinence, .bloating,
             .breastPain, .chestTightnessOrPain, .chills, .constipation, .coughing,
             .diarrhea, .dizziness, .drySkin, .fainting, .fatigue, .fever,
             .generalizedBodyAche, .hairLoss, .headache, .heartburn, .hotFlashes,
             .lossOfSmell, .lossOfTaste, .lowerBackPain, .memoryLapse, .moodChanges,
             .nausea, .nightSweats, .pelvicPain, .rapidPoundingOrFlutteringHeartbeat,
             .runnyNose, .shortnessOfBreath, .sinusCongestion, .skippedHeartbeat,
             .sleepChanges, .soreThroat, .vaginalDryness, .vomiting, .wheezing,
             .menstrualFlow, .intermenstrualBleeding, .infrequentMenstrualCycles,
             .irregularMenstrualCycles, .persistentIntermenstrualBleeding,
             .prolongedMenstrualPeriods, .ovulationTestResult, .pregnancyTestResult,
             .progesteroneTestResult, .sexualActivity, .cervicalMucusQuality,
             .contraceptive, .lactation, .bleedingAfterPregnancy, .bleedingDuringPregnancy,
             .handwashingEvent, .toothbrushingEvent, .environmentalAudioExposureEvent,
             .headphoneAudioExposureEvent, .lowCardioFitnessEvent,
             .appleWalkingSteadinessEvent, .appleStandHour:
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
    // Comprehensive mapping of all HKWorkoutActivityType cases to stable string identifiers.
    // These strings are the wire-format names used in HealthSampleDTO.metadata["activityType"].
    // Names use camelCase matching Apple's HKWorkoutActivityType case names so consumers can
    // correlate without a separate translation table.
    var name: String {
        switch self {
        // Cardio / endurance
        case .running: return "running"
        case .walking: return "walking"
        case .hiking: return "hiking"
        case .cycling: return "cycling"
        case .handCycling: return "handCycling"
        case .stairs: return "stairs"
        case .stairClimbing: return "stairClimbing"
        case .stepTraining: return "stepTraining"
        case .elliptical: return "elliptical"
        case .rowing: return "rowing"
        case .crossCountrySkiing: return "crossCountrySkiing"

        // Strength / functional / mind-body
        case .functionalStrengthTraining: return "functionalStrengthTraining"
        case .traditionalStrengthTraining: return "traditionalStrengthTraining"
        case .crossTraining: return "crossTraining"
        case .coreTraining: return "coreTraining"
        case .highIntensityIntervalTraining: return "highIntensityIntervalTraining"
        case .mixedCardio: return "mixedCardio"
        case .mixedMetabolicCardioTraining: return "mixedMetabolicCardioTraining"
        case .preparationAndRecovery: return "preparationAndRecovery"
        case .cooldown: return "cooldown"
        case .flexibility: return "flexibility"
        case .barre: return "barre"
        case .pilates: return "pilates"
        case .yoga: return "yoga"
        case .taiChi: return "taiChi"
        case .mindAndBody: return "mindAndBody"
        case .gymnastics: return "gymnastics"
        case .jumpRope: return "jumpRope"
        case .kickboxing: return "kickboxing"
        case .martialArts: return "martialArts"
        case .boxing: return "boxing"
        case .wrestling: return "wrestling"
        case .fencing: return "fencing"
        case .climbing: return "climbing"

        // Dance
        case .dance: return "dance"
        case .danceInspiredTraining: return "danceInspiredTraining"
        case .cardioDance: return "cardioDance"
        case .socialDance: return "socialDance"

        // Ball / racquet sports
        case .americanFootball: return "americanFootball"
        case .australianFootball: return "australianFootball"
        case .soccer: return "soccer"
        case .rugby: return "rugby"
        case .baseball: return "baseball"
        case .softball: return "softball"
        case .basketball: return "basketball"
        case .volleyball: return "volleyball"
        case .handball: return "handball"
        case .lacrosse: return "lacrosse"
        case .hockey: return "hockey"
        case .cricket: return "cricket"
        case .tennis: return "tennis"
        case .tableTennis: return "tableTennis"
        case .badminton: return "badminton"
        case .squash: return "squash"
        case .racquetball: return "racquetball"
        case .pickleball: return "pickleball"
        case .golf: return "golf"
        case .bowling: return "bowling"
        case .discSports: return "discSports"

        // Snow / winter
        case .snowSports: return "snowSports"
        case .snowboarding: return "snowboarding"
        case .downhillSkiing: return "downhillSkiing"
        case .skatingSports: return "skatingSports"
        case .curling: return "curling"

        // Water
        case .swimming: return "swimming"
        case .waterFitness: return "waterFitness"
        case .waterPolo: return "waterPolo"
        case .waterSports: return "waterSports"
        case .surfingSports: return "surfingSports"
        case .paddleSports: return "paddleSports"
        case .swimBikeRun: return "swimBikeRun"
        case .underwaterDiving: return "underwaterDiving"

        // Outdoor / leisure
        case .archery: return "archery"
        case .equestrianSports: return "equestrianSports"
        case .fishing: return "fishing"
        case .hunting: return "hunting"
        case .play: return "play"
        case .trackAndField: return "trackAndField"

        // Wheelchair
        case .wheelchairWalkPace: return "wheelchairWalkPace"
        case .wheelchairRunPace: return "wheelchairRunPace"

        // Multi-sport / other
        case .fitnessGaming: return "fitnessGaming"
        case .transition: return "transition"
        case .other: return "other"
        @unknown default: return "other"
        }
    }
}
