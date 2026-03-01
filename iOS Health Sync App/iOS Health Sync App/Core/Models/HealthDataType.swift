// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation
import HealthKit

enum HealthDataType: String, CaseIterable, Codable, Sendable, Identifiable {
    case steps
    case distanceWalkingRunning
    case distanceCycling
    case activeEnergyBurned
    case basalEnergyBurned
    case exerciseTime
    case standHours
    case flightsClimbed
    case workouts

    case dietaryEnergyConsumed
    case dietaryWater
    case dietaryProtein
    case dietaryCarbohydrates
    case dietaryFiber
    case dietarySugar
    case dietaryFatTotal
    case dietaryFatSaturated
    case dietaryFatMonounsaturated
    case dietaryFatPolyunsaturated
    case dietaryCholesterol
    case dietarySodium
    case dietaryPotassium
    case dietaryCalcium
    case dietaryIron
    case dietaryMagnesium
    case dietaryPhosphorus
    case dietaryZinc
    case dietaryChloride
    case dietaryCopper
    case dietaryManganese
    case dietarySelenium
    case dietaryMolybdenum
    case dietaryIodine
    case dietaryChromium
    case dietaryBiotin
    case dietaryFolate
    case dietaryNiacin
    case dietaryPantothenicAcid
    case dietaryRiboflavin
    case dietaryThiamin
    case dietaryVitaminA
    case dietaryVitaminB6
    case dietaryVitaminB12
    case dietaryVitaminC
    case dietaryVitaminD
    case dietaryVitaminE
    case dietaryVitaminK
    case dietaryCaffeine

    case heartRate
    case restingHeartRate
    case walkingHeartRateAverage
    case heartRateVariability
    case bloodPressureSystolic
    case bloodPressureDiastolic
    case bloodOxygen
    case respiratoryRate
    case bodyTemperature
    case vo2Max

    case sleepAnalysis
    case sleepInBed
    case sleepAsleep
    case sleepAwake
    case sleepREM
    case sleepCore
    case sleepDeep

    case weight
    case height
    case bodyMassIndex
    case bodyFatPercentage
    case leanBodyMass

    /// Data types supported by CLI v1.0.0 before dietary metrics were added.
    static let legacyV1AllCases: [HealthDataType] = [
        .steps,
        .distanceWalkingRunning,
        .distanceCycling,
        .activeEnergyBurned,
        .basalEnergyBurned,
        .exerciseTime,
        .standHours,
        .flightsClimbed,
        .workouts,
        .heartRate,
        .restingHeartRate,
        .walkingHeartRateAverage,
        .heartRateVariability,
        .bloodPressureSystolic,
        .bloodPressureDiastolic,
        .bloodOxygen,
        .respiratoryRate,
        .bodyTemperature,
        .vo2Max,
        .sleepAnalysis,
        .sleepInBed,
        .sleepAsleep,
        .sleepAwake,
        .sleepREM,
        .sleepCore,
        .sleepDeep,
        .weight,
        .height,
        .bodyMassIndex,
        .bodyFatPercentage,
        .leanBodyMass
    ]

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .distanceWalkingRunning: return "Walking + Running Distance"
        case .distanceCycling: return "Cycling Distance"
        case .activeEnergyBurned: return "Active Energy"
        case .basalEnergyBurned: return "Basal Energy"
        case .exerciseTime: return "Exercise Time"
        case .standHours: return "Stand Hours"
        case .flightsClimbed: return "Flights Climbed"
        case .workouts: return "Workouts"
        case .dietaryEnergyConsumed: return "Dietary Calories"
        case .dietaryWater: return "Dietary Water"
        case .dietaryProtein: return "Dietary Protein"
        case .dietaryCarbohydrates: return "Dietary Carbohydrates"
        case .dietaryFiber: return "Dietary Fiber"
        case .dietarySugar: return "Dietary Sugar"
        case .dietaryFatTotal: return "Dietary Fat Total"
        case .dietaryFatSaturated: return "Dietary Saturated Fat"
        case .dietaryFatMonounsaturated: return "Dietary Monounsaturated Fat"
        case .dietaryFatPolyunsaturated: return "Dietary Polyunsaturated Fat"
        case .dietaryCholesterol: return "Dietary Cholesterol"
        case .dietarySodium: return "Dietary Sodium"
        case .dietaryPotassium: return "Dietary Potassium"
        case .dietaryCalcium: return "Dietary Calcium"
        case .dietaryIron: return "Dietary Iron"
        case .dietaryMagnesium: return "Dietary Magnesium"
        case .dietaryPhosphorus: return "Dietary Phosphorus"
        case .dietaryZinc: return "Dietary Zinc"
        case .dietaryChloride: return "Dietary Chloride"
        case .dietaryCopper: return "Dietary Copper"
        case .dietaryManganese: return "Dietary Manganese"
        case .dietarySelenium: return "Dietary Selenium"
        case .dietaryMolybdenum: return "Dietary Molybdenum"
        case .dietaryIodine: return "Dietary Iodine"
        case .dietaryChromium: return "Dietary Chromium"
        case .dietaryBiotin: return "Dietary Biotin"
        case .dietaryFolate: return "Dietary Folate"
        case .dietaryNiacin: return "Dietary Niacin"
        case .dietaryPantothenicAcid: return "Dietary Pantothenic Acid"
        case .dietaryRiboflavin: return "Dietary Riboflavin"
        case .dietaryThiamin: return "Dietary Thiamin"
        case .dietaryVitaminA: return "Dietary Vitamin A"
        case .dietaryVitaminB6: return "Dietary Vitamin B6"
        case .dietaryVitaminB12: return "Dietary Vitamin B12"
        case .dietaryVitaminC: return "Dietary Vitamin C"
        case .dietaryVitaminD: return "Dietary Vitamin D"
        case .dietaryVitaminE: return "Dietary Vitamin E"
        case .dietaryVitaminK: return "Dietary Vitamin K"
        case .dietaryCaffeine: return "Dietary Caffeine"
        case .heartRate: return "Heart Rate"
        case .restingHeartRate: return "Resting Heart Rate"
        case .walkingHeartRateAverage: return "Walking HR Avg"
        case .heartRateVariability: return "HRV"
        case .bloodPressureSystolic: return "Blood Pressure Systolic"
        case .bloodPressureDiastolic: return "Blood Pressure Diastolic"
        case .bloodOxygen: return "Blood Oxygen"
        case .respiratoryRate: return "Respiratory Rate"
        case .bodyTemperature: return "Body Temperature"
        case .vo2Max: return "VO2 Max"
        case .sleepAnalysis: return "Sleep Analysis"
        case .sleepInBed: return "Sleep In Bed"
        case .sleepAsleep: return "Sleep Asleep"
        case .sleepAwake: return "Sleep Awake"
        case .sleepREM: return "Sleep REM"
        case .sleepCore: return "Sleep Core"
        case .sleepDeep: return "Sleep Deep"
        case .weight: return "Weight"
        case .height: return "Height"
        case .bodyMassIndex: return "Body Mass Index"
        case .bodyFatPercentage: return "Body Fat %"
        case .leanBodyMass: return "Lean Body Mass"
        }
    }

    var sampleType: HKSampleType? {
        switch self {
        case .steps: return HKObjectType.quantityType(forIdentifier: .stepCount)
        case .distanceWalkingRunning: return HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
        case .distanceCycling: return HKObjectType.quantityType(forIdentifier: .distanceCycling)
        case .activeEnergyBurned: return HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        case .basalEnergyBurned: return HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)
        case .exerciseTime: return HKObjectType.quantityType(forIdentifier: .appleExerciseTime)
        case .standHours: return HKObjectType.quantityType(forIdentifier: .appleStandTime)
        case .flightsClimbed: return HKObjectType.quantityType(forIdentifier: .flightsClimbed)
        case .workouts: return HKObjectType.workoutType()
        case .dietaryEnergyConsumed: return HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)
        case .dietaryWater: return HKObjectType.quantityType(forIdentifier: .dietaryWater)
        case .dietaryProtein: return HKObjectType.quantityType(forIdentifier: .dietaryProtein)
        case .dietaryCarbohydrates: return HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)
        case .dietaryFiber: return HKObjectType.quantityType(forIdentifier: .dietaryFiber)
        case .dietarySugar: return HKObjectType.quantityType(forIdentifier: .dietarySugar)
        case .dietaryFatTotal: return HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)
        case .dietaryFatSaturated: return HKObjectType.quantityType(forIdentifier: .dietaryFatSaturated)
        case .dietaryFatMonounsaturated: return HKObjectType.quantityType(forIdentifier: .dietaryFatMonounsaturated)
        case .dietaryFatPolyunsaturated: return HKObjectType.quantityType(forIdentifier: .dietaryFatPolyunsaturated)
        case .dietaryCholesterol: return HKObjectType.quantityType(forIdentifier: .dietaryCholesterol)
        case .dietarySodium: return HKObjectType.quantityType(forIdentifier: .dietarySodium)
        case .dietaryPotassium: return HKObjectType.quantityType(forIdentifier: .dietaryPotassium)
        case .dietaryCalcium: return HKObjectType.quantityType(forIdentifier: .dietaryCalcium)
        case .dietaryIron: return HKObjectType.quantityType(forIdentifier: .dietaryIron)
        case .dietaryMagnesium: return HKObjectType.quantityType(forIdentifier: .dietaryMagnesium)
        case .dietaryPhosphorus: return HKObjectType.quantityType(forIdentifier: .dietaryPhosphorus)
        case .dietaryZinc: return HKObjectType.quantityType(forIdentifier: .dietaryZinc)
        case .dietaryChloride: return HKObjectType.quantityType(forIdentifier: .dietaryChloride)
        case .dietaryCopper: return HKObjectType.quantityType(forIdentifier: .dietaryCopper)
        case .dietaryManganese: return HKObjectType.quantityType(forIdentifier: .dietaryManganese)
        case .dietarySelenium: return HKObjectType.quantityType(forIdentifier: .dietarySelenium)
        case .dietaryMolybdenum: return HKObjectType.quantityType(forIdentifier: .dietaryMolybdenum)
        case .dietaryIodine: return HKObjectType.quantityType(forIdentifier: .dietaryIodine)
        case .dietaryChromium: return HKObjectType.quantityType(forIdentifier: .dietaryChromium)
        case .dietaryBiotin: return HKObjectType.quantityType(forIdentifier: .dietaryBiotin)
        case .dietaryFolate: return HKObjectType.quantityType(forIdentifier: .dietaryFolate)
        case .dietaryNiacin: return HKObjectType.quantityType(forIdentifier: .dietaryNiacin)
        case .dietaryPantothenicAcid: return HKObjectType.quantityType(forIdentifier: .dietaryPantothenicAcid)
        case .dietaryRiboflavin: return HKObjectType.quantityType(forIdentifier: .dietaryRiboflavin)
        case .dietaryThiamin: return HKObjectType.quantityType(forIdentifier: .dietaryThiamin)
        case .dietaryVitaminA: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminA)
        case .dietaryVitaminB6: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminB6)
        case .dietaryVitaminB12: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminB12)
        case .dietaryVitaminC: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminC)
        case .dietaryVitaminD: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminD)
        case .dietaryVitaminE: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminE)
        case .dietaryVitaminK: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminK)
        case .dietaryCaffeine: return HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)
        case .heartRate: return HKObjectType.quantityType(forIdentifier: .heartRate)
        case .restingHeartRate: return HKObjectType.quantityType(forIdentifier: .restingHeartRate)
        case .walkingHeartRateAverage: return HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage)
        case .heartRateVariability: return HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
        case .bloodPressureSystolic: return HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)
        case .bloodPressureDiastolic: return HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)
        case .bloodOxygen: return HKObjectType.quantityType(forIdentifier: .oxygenSaturation)
        case .respiratoryRate: return HKObjectType.quantityType(forIdentifier: .respiratoryRate)
        case .bodyTemperature: return HKObjectType.quantityType(forIdentifier: .bodyTemperature)
        case .vo2Max: return HKObjectType.quantityType(forIdentifier: .vo2Max)
        case .sleepAnalysis: return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        case .sleepInBed: return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        case .sleepAsleep: return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        case .sleepAwake: return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        case .sleepREM: return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        case .sleepCore: return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        case .sleepDeep: return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        case .weight: return HKObjectType.quantityType(forIdentifier: .bodyMass)
        case .height: return HKObjectType.quantityType(forIdentifier: .height)
        case .bodyMassIndex: return HKObjectType.quantityType(forIdentifier: .bodyMassIndex)
        case .bodyFatPercentage: return HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)
        case .leanBodyMass: return HKObjectType.quantityType(forIdentifier: .leanBodyMass)
        }
    }

    var isCategorySleepType: Bool {
        switch self {
        case .sleepAnalysis, .sleepInBed, .sleepAsleep, .sleepAwake, .sleepREM, .sleepCore, .sleepDeep:
            return true
        default:
            return false
        }
    }
}
