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
