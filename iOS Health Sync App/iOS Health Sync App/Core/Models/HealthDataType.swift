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

    // Cardiac events
    case irregularHeartRhythmEvent
    case highHeartRateEvent
    case lowHeartRateEvent
    case heartRateRecoveryOneMinute

    // Blood / metabolic
    case bloodGlucose
    case peripheralPerfusionIndex

    // Swimming
    case distanceSwimming
    case swimmingStrokeCount

    // Other sports / adaptive
    case distanceDownhillSnowSports
    case distanceWheelchair
    case pushCount

    // Cycling performance
    case cyclingFunctionalThresholdPower

    // Diving / water sports
    case underwaterDepth
    case waterTemperature

    // Hearing
    case environmentalAudioExposure
    case headphoneAudioExposure

    // Safety / lifestyle
    case numberOfTimesFallen
    case numberOfAlcoholicBeverages

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
        case .irregularHeartRhythmEvent: return "Irregular Rhythm Event"
        case .highHeartRateEvent: return "High Heart Rate Event"
        case .lowHeartRateEvent: return "Low Heart Rate Event"
        case .heartRateRecoveryOneMinute: return "HR Recovery (1 min)"
        case .bloodGlucose: return "Blood Glucose"
        case .peripheralPerfusionIndex: return "Peripheral Perfusion Index"
        case .distanceSwimming: return "Swimming Distance"
        case .swimmingStrokeCount: return "Swimming Stroke Count"
        case .distanceDownhillSnowSports: return "Downhill Snow Sports Distance"
        case .distanceWheelchair: return "Wheelchair Distance"
        case .pushCount: return "Push Count"
        case .cyclingFunctionalThresholdPower: return "Cycling FTP"
        case .underwaterDepth: return "Underwater Depth"
        case .waterTemperature: return "Water Temperature"
        case .environmentalAudioExposure: return "Environmental Audio Exposure"
        case .headphoneAudioExposure: return "Headphone Audio Exposure"
        case .numberOfTimesFallen: return "Times Fallen"
        case .numberOfAlcoholicBeverages: return "Alcoholic Beverages"
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
        case .irregularHeartRhythmEvent: return HKObjectType.categoryType(forIdentifier: .irregularHeartRhythmEvent)
        case .highHeartRateEvent: return HKObjectType.categoryType(forIdentifier: .highHeartRateEvent)
        case .lowHeartRateEvent: return HKObjectType.categoryType(forIdentifier: .lowHeartRateEvent)
        case .heartRateRecoveryOneMinute: return HKObjectType.quantityType(forIdentifier: .heartRateRecoveryOneMinute)
        case .bloodGlucose: return HKObjectType.quantityType(forIdentifier: .bloodGlucose)
        case .peripheralPerfusionIndex: return HKObjectType.quantityType(forIdentifier: .peripheralPerfusionIndex)
        case .distanceSwimming: return HKObjectType.quantityType(forIdentifier: .distanceSwimming)
        case .swimmingStrokeCount: return HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)
        case .distanceDownhillSnowSports: return HKObjectType.quantityType(forIdentifier: .distanceDownhillSnowSports)
        case .distanceWheelchair: return HKObjectType.quantityType(forIdentifier: .distanceWheelchair)
        case .pushCount: return HKObjectType.quantityType(forIdentifier: .pushCount)
        case .cyclingFunctionalThresholdPower: return HKObjectType.quantityType(forIdentifier: .cyclingFunctionalThresholdPower)
        case .underwaterDepth: return HKObjectType.quantityType(forIdentifier: .underwaterDepth)
        case .waterTemperature: return HKObjectType.quantityType(forIdentifier: .waterTemperature)
        case .environmentalAudioExposure: return HKObjectType.quantityType(forIdentifier: .environmentalAudioExposure)
        case .headphoneAudioExposure: return HKObjectType.quantityType(forIdentifier: .headphoneAudioExposure)
        case .numberOfTimesFallen: return HKObjectType.quantityType(forIdentifier: .numberOfTimesFallen)
        case .numberOfAlcoholicBeverages: return HKObjectType.quantityType(forIdentifier: .numberOfAlcoholicBeverages)
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
