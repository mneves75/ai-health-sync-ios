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

    // Running dynamics
    case waistCircumference
    case runningGroundContactTime
    case runningStrideLength
    case runningVerticalOscillation
    case runningPower
    case runningSpeed

    // Cycling dynamics
    case cyclingCadence
    case cyclingPower
    case cyclingSpeed

    // Walking / mobility
    case walkingSpeed
    case walkingStepLength
    case walkingAsymmetryPercentage
    case walkingDoubleSupportPercentage
    case stairAscentSpeed
    case stairDescentSpeed

    // Advanced health
    case wristTemperature
    case atrialFibrillationBurden
    case timeInDaylight
    case physicalEffort
    case mindfulMinutes

    // Nutrition — energy and water
    case dietaryEnergyConsumed
    case dietaryWater
    case dietaryCaffeine

    // Nutrition — macronutrients
    case dietaryProtein
    case dietaryFatTotal
    case dietaryFatSaturated
    case dietaryFatPolyunsaturated
    case dietaryFatMonounsaturated
    case dietaryCholesterol
    case dietaryCarbohydrates
    case dietaryFiber
    case dietarySugar

    // Nutrition — minerals
    case dietarySodium
    case dietaryCalcium
    case dietaryIron
    case dietaryMagnesium
    case dietaryPotassium
    case dietaryZinc
    case dietaryPhosphorus
    case dietaryIodine
    case dietarySelenium
    case dietaryCopper
    case dietaryManganese
    case dietaryChromium
    case dietaryMolybdenum
    case dietaryChloride

    // Nutrition — vitamins
    case dietaryVitaminA
    case dietaryVitaminB6
    case dietaryVitaminB12
    case dietaryVitaminC
    case dietaryVitaminD
    case dietaryVitaminE
    case dietaryVitaminK
    case dietaryRiboflavin
    case dietaryThiamin
    case dietaryNiacin
    case dietaryFolate
    case dietaryBiotin
    case dietaryPantothenicAcid

    // Symptoms
    case abdominalCramps
    case acne
    case appetiteChanges
    case bladderIncontinence
    case bloating
    case breastPain
    case chestTightnessOrPain
    case chills
    case constipation
    case coughing
    case diarrhea
    case dizziness
    case drySkin
    case fainting
    case fatigue
    case fever
    case generalizedBodyAche
    case hairLoss
    case headache
    case heartburn
    case hotFlashes
    case lossOfSmell
    case lossOfTaste
    case lowerBackPain
    case memoryLapse
    case moodChanges
    case nausea
    case nightSweats
    case pelvicPain
    case rapidPoundingOrFlutteringHeartbeat
    case runnyNose
    case shortnessOfBreath
    case sinusCongestion
    case skippedHeartbeat
    case sleepChanges
    case soreThroat
    case vaginalDryness
    case vomiting
    case wheezing

    // Reproductive health
    case menstrualFlow
    case intermenstrualBleeding
    case infrequentMenstrualCycles
    case irregularMenstrualCycles
    case persistentIntermenstrualBleeding
    case prolongedMenstrualPeriods
    case ovulationTestResult
    case pregnancyTestResult
    case progesteroneTestResult
    case sexualActivity
    case cervicalMucusQuality
    case contraceptive
    case lactation
    case bleedingAfterPregnancy
    case bleedingDuringPregnancy

    // Lifestyle / hygiene events
    case handwashingEvent
    case toothbrushingEvent

    // Audio events
    case environmentalAudioExposureEvent
    case headphoneAudioExposureEvent

    // Cardio fitness / mobility events
    case lowCardioFitnessEvent
    case appleWalkingSteadinessEvent
    case appleStandHour

    // Vital signs / spirometry
    case basalBodyTemperature
    case bloodAlcoholContent
    case electrodermalActivity
    case environmentalSoundReduction
    case forcedExpiratoryVolume1
    case forcedVitalCapacity
    case peakExpiratoryFlowRate
    case inhalerUsage
    case insulinDelivery
    case nikeFuel
    case sixMinuteWalkTestDistance
    case appleWalkingSteadiness
    case uvExposure
    case appleMoveTime

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
        case .waistCircumference: return "Waist Circumference"
        case .runningGroundContactTime: return "Running Ground Contact Time"
        case .runningStrideLength: return "Running Stride Length"
        case .runningVerticalOscillation: return "Running Vertical Oscillation"
        case .runningPower: return "Running Power"
        case .runningSpeed: return "Running Speed"
        case .cyclingCadence: return "Cycling Cadence"
        case .cyclingPower: return "Cycling Power"
        case .cyclingSpeed: return "Cycling Speed"
        case .walkingSpeed: return "Walking Speed"
        case .walkingStepLength: return "Walking Step Length"
        case .walkingAsymmetryPercentage: return "Walking Asymmetry"
        case .walkingDoubleSupportPercentage: return "Walking Double Support"
        case .stairAscentSpeed: return "Stair Ascent Speed"
        case .stairDescentSpeed: return "Stair Descent Speed"
        case .wristTemperature: return "Wrist Temperature"
        case .atrialFibrillationBurden: return "AFib Burden"
        case .timeInDaylight: return "Time in Daylight"
        case .physicalEffort: return "Physical Effort"
        case .mindfulMinutes: return "Mindful Minutes"
        case .dietaryEnergyConsumed: return "Dietary Energy"
        case .dietaryWater: return "Water"
        case .dietaryCaffeine: return "Caffeine"
        case .dietaryProtein: return "Protein"
        case .dietaryFatTotal: return "Total Fat"
        case .dietaryFatSaturated: return "Saturated Fat"
        case .dietaryFatPolyunsaturated: return "Polyunsaturated Fat"
        case .dietaryFatMonounsaturated: return "Monounsaturated Fat"
        case .dietaryCholesterol: return "Cholesterol"
        case .dietaryCarbohydrates: return "Carbohydrates"
        case .dietaryFiber: return "Fiber"
        case .dietarySugar: return "Sugar"
        case .dietarySodium: return "Sodium"
        case .dietaryCalcium: return "Calcium"
        case .dietaryIron: return "Iron"
        case .dietaryMagnesium: return "Magnesium"
        case .dietaryPotassium: return "Potassium"
        case .dietaryZinc: return "Zinc"
        case .dietaryPhosphorus: return "Phosphorus"
        case .dietaryIodine: return "Iodine"
        case .dietarySelenium: return "Selenium"
        case .dietaryCopper: return "Copper"
        case .dietaryManganese: return "Manganese"
        case .dietaryChromium: return "Chromium"
        case .dietaryMolybdenum: return "Molybdenum"
        case .dietaryChloride: return "Chloride"
        case .dietaryVitaminA: return "Vitamin A"
        case .dietaryVitaminB6: return "Vitamin B6"
        case .dietaryVitaminB12: return "Vitamin B12"
        case .dietaryVitaminC: return "Vitamin C"
        case .dietaryVitaminD: return "Vitamin D"
        case .dietaryVitaminE: return "Vitamin E"
        case .dietaryVitaminK: return "Vitamin K"
        case .dietaryRiboflavin: return "Riboflavin"
        case .dietaryThiamin: return "Thiamin"
        case .dietaryNiacin: return "Niacin"
        case .dietaryFolate: return "Folate"
        case .dietaryBiotin: return "Biotin"
        case .dietaryPantothenicAcid: return "Pantothenic Acid"
        case .abdominalCramps: return "Abdominal Cramps"
        case .acne: return "Acne"
        case .appetiteChanges: return "Appetite Changes"
        case .bladderIncontinence: return "Bladder Incontinence"
        case .bloating: return "Bloating"
        case .breastPain: return "Breast Pain"
        case .chestTightnessOrPain: return "Chest Tightness/Pain"
        case .chills: return "Chills"
        case .constipation: return "Constipation"
        case .coughing: return "Coughing"
        case .diarrhea: return "Diarrhea"
        case .dizziness: return "Dizziness"
        case .drySkin: return "Dry Skin"
        case .fainting: return "Fainting"
        case .fatigue: return "Fatigue"
        case .fever: return "Fever"
        case .generalizedBodyAche: return "Body Ache"
        case .hairLoss: return "Hair Loss"
        case .headache: return "Headache"
        case .heartburn: return "Heartburn"
        case .hotFlashes: return "Hot Flashes"
        case .lossOfSmell: return "Loss of Smell"
        case .lossOfTaste: return "Loss of Taste"
        case .lowerBackPain: return "Lower Back Pain"
        case .memoryLapse: return "Memory Lapse"
        case .moodChanges: return "Mood Changes"
        case .nausea: return "Nausea"
        case .nightSweats: return "Night Sweats"
        case .pelvicPain: return "Pelvic Pain"
        case .rapidPoundingOrFlutteringHeartbeat: return "Heart Pounding/Fluttering"
        case .runnyNose: return "Runny Nose"
        case .shortnessOfBreath: return "Shortness of Breath"
        case .sinusCongestion: return "Sinus Congestion"
        case .skippedHeartbeat: return "Skipped Heartbeat"
        case .sleepChanges: return "Sleep Changes"
        case .soreThroat: return "Sore Throat"
        case .vaginalDryness: return "Vaginal Dryness"
        case .vomiting: return "Vomiting"
        case .wheezing: return "Wheezing"
        case .menstrualFlow: return "Menstrual Flow"
        case .intermenstrualBleeding: return "Intermenstrual Bleeding"
        case .infrequentMenstrualCycles: return "Infrequent Periods"
        case .irregularMenstrualCycles: return "Irregular Periods"
        case .persistentIntermenstrualBleeding: return "Persistent Intermenstrual Bleeding"
        case .prolongedMenstrualPeriods: return "Prolonged Periods"
        case .ovulationTestResult: return "Ovulation Test"
        case .pregnancyTestResult: return "Pregnancy Test"
        case .progesteroneTestResult: return "Progesterone Test"
        case .sexualActivity: return "Sexual Activity"
        case .cervicalMucusQuality: return "Cervical Mucus"
        case .contraceptive: return "Contraceptive"
        case .lactation: return "Lactation"
        case .bleedingAfterPregnancy: return "Bleeding After Pregnancy"
        case .bleedingDuringPregnancy: return "Bleeding During Pregnancy"
        case .handwashingEvent: return "Handwashing"
        case .toothbrushingEvent: return "Toothbrushing"
        case .environmentalAudioExposureEvent: return "Loud Environment Event"
        case .headphoneAudioExposureEvent: return "Loud Headphones Event"
        case .lowCardioFitnessEvent: return "Low Cardio Fitness Event"
        case .appleWalkingSteadinessEvent: return "Walking Steadiness Event"
        case .appleStandHour: return "Stand Hour"
        case .basalBodyTemperature: return "Basal Body Temperature"
        case .bloodAlcoholContent: return "Blood Alcohol"
        case .electrodermalActivity: return "Electrodermal Activity"
        case .environmentalSoundReduction: return "Sound Reduction"
        case .forcedExpiratoryVolume1: return "FEV1"
        case .forcedVitalCapacity: return "Forced Vital Capacity"
        case .peakExpiratoryFlowRate: return "Peak Expiratory Flow"
        case .inhalerUsage: return "Inhaler Usage"
        case .insulinDelivery: return "Insulin Delivery"
        case .nikeFuel: return "NikeFuel"
        case .sixMinuteWalkTestDistance: return "6-Min Walk Test"
        case .appleWalkingSteadiness: return "Walking Steadiness"
        case .uvExposure: return "UV Exposure"
        case .appleMoveTime: return "Move Time"
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
        case .waistCircumference: return HKObjectType.quantityType(forIdentifier: .waistCircumference)
        case .runningGroundContactTime: return HKObjectType.quantityType(forIdentifier: .runningGroundContactTime)
        case .runningStrideLength: return HKObjectType.quantityType(forIdentifier: .runningStrideLength)
        case .runningVerticalOscillation: return HKObjectType.quantityType(forIdentifier: .runningVerticalOscillation)
        case .runningPower: return HKObjectType.quantityType(forIdentifier: .runningPower)
        case .runningSpeed: return HKObjectType.quantityType(forIdentifier: .runningSpeed)
        case .cyclingCadence: return HKObjectType.quantityType(forIdentifier: .cyclingCadence)
        case .cyclingPower: return HKObjectType.quantityType(forIdentifier: .cyclingPower)
        case .cyclingSpeed: return HKObjectType.quantityType(forIdentifier: .cyclingSpeed)
        case .walkingSpeed: return HKObjectType.quantityType(forIdentifier: .walkingSpeed)
        case .walkingStepLength: return HKObjectType.quantityType(forIdentifier: .walkingStepLength)
        case .walkingAsymmetryPercentage: return HKObjectType.quantityType(forIdentifier: .walkingAsymmetryPercentage)
        case .walkingDoubleSupportPercentage: return HKObjectType.quantityType(forIdentifier: .walkingDoubleSupportPercentage)
        case .stairAscentSpeed: return HKObjectType.quantityType(forIdentifier: .stairAscentSpeed)
        case .stairDescentSpeed: return HKObjectType.quantityType(forIdentifier: .stairDescentSpeed)
        case .wristTemperature: return HKObjectType.quantityType(forIdentifier: .appleSleepingWristTemperature)
        case .atrialFibrillationBurden: return HKObjectType.quantityType(forIdentifier: .atrialFibrillationBurden)
        case .timeInDaylight: return HKObjectType.quantityType(forIdentifier: .timeInDaylight)
        case .physicalEffort: return HKObjectType.quantityType(forIdentifier: .physicalEffort)
        case .mindfulMinutes: return HKObjectType.categoryType(forIdentifier: .mindfulSession)
        case .dietaryEnergyConsumed: return HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)
        case .dietaryWater: return HKObjectType.quantityType(forIdentifier: .dietaryWater)
        case .dietaryCaffeine: return HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)
        case .dietaryProtein: return HKObjectType.quantityType(forIdentifier: .dietaryProtein)
        case .dietaryFatTotal: return HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)
        case .dietaryFatSaturated: return HKObjectType.quantityType(forIdentifier: .dietaryFatSaturated)
        case .dietaryFatPolyunsaturated: return HKObjectType.quantityType(forIdentifier: .dietaryFatPolyunsaturated)
        case .dietaryFatMonounsaturated: return HKObjectType.quantityType(forIdentifier: .dietaryFatMonounsaturated)
        case .dietaryCholesterol: return HKObjectType.quantityType(forIdentifier: .dietaryCholesterol)
        case .dietaryCarbohydrates: return HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)
        case .dietaryFiber: return HKObjectType.quantityType(forIdentifier: .dietaryFiber)
        case .dietarySugar: return HKObjectType.quantityType(forIdentifier: .dietarySugar)
        case .dietarySodium: return HKObjectType.quantityType(forIdentifier: .dietarySodium)
        case .dietaryCalcium: return HKObjectType.quantityType(forIdentifier: .dietaryCalcium)
        case .dietaryIron: return HKObjectType.quantityType(forIdentifier: .dietaryIron)
        case .dietaryMagnesium: return HKObjectType.quantityType(forIdentifier: .dietaryMagnesium)
        case .dietaryPotassium: return HKObjectType.quantityType(forIdentifier: .dietaryPotassium)
        case .dietaryZinc: return HKObjectType.quantityType(forIdentifier: .dietaryZinc)
        case .dietaryPhosphorus: return HKObjectType.quantityType(forIdentifier: .dietaryPhosphorus)
        case .dietaryIodine: return HKObjectType.quantityType(forIdentifier: .dietaryIodine)
        case .dietarySelenium: return HKObjectType.quantityType(forIdentifier: .dietarySelenium)
        case .dietaryCopper: return HKObjectType.quantityType(forIdentifier: .dietaryCopper)
        case .dietaryManganese: return HKObjectType.quantityType(forIdentifier: .dietaryManganese)
        case .dietaryChromium: return HKObjectType.quantityType(forIdentifier: .dietaryChromium)
        case .dietaryMolybdenum: return HKObjectType.quantityType(forIdentifier: .dietaryMolybdenum)
        case .dietaryChloride: return HKObjectType.quantityType(forIdentifier: .dietaryChloride)
        case .dietaryVitaminA: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminA)
        case .dietaryVitaminB6: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminB6)
        case .dietaryVitaminB12: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminB12)
        case .dietaryVitaminC: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminC)
        case .dietaryVitaminD: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminD)
        case .dietaryVitaminE: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminE)
        case .dietaryVitaminK: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminK)
        case .dietaryRiboflavin: return HKObjectType.quantityType(forIdentifier: .dietaryRiboflavin)
        case .dietaryThiamin: return HKObjectType.quantityType(forIdentifier: .dietaryThiamin)
        case .dietaryNiacin: return HKObjectType.quantityType(forIdentifier: .dietaryNiacin)
        case .dietaryFolate: return HKObjectType.quantityType(forIdentifier: .dietaryFolate)
        case .dietaryBiotin: return HKObjectType.quantityType(forIdentifier: .dietaryBiotin)
        case .dietaryPantothenicAcid: return HKObjectType.quantityType(forIdentifier: .dietaryPantothenicAcid)
        case .abdominalCramps: return HKObjectType.categoryType(forIdentifier: .abdominalCramps)
        case .acne: return HKObjectType.categoryType(forIdentifier: .acne)
        case .appetiteChanges: return HKObjectType.categoryType(forIdentifier: .appetiteChanges)
        case .bladderIncontinence: return HKObjectType.categoryType(forIdentifier: .bladderIncontinence)
        case .bloating: return HKObjectType.categoryType(forIdentifier: .bloating)
        case .breastPain: return HKObjectType.categoryType(forIdentifier: .breastPain)
        case .chestTightnessOrPain: return HKObjectType.categoryType(forIdentifier: .chestTightnessOrPain)
        case .chills: return HKObjectType.categoryType(forIdentifier: .chills)
        case .constipation: return HKObjectType.categoryType(forIdentifier: .constipation)
        case .coughing: return HKObjectType.categoryType(forIdentifier: .coughing)
        case .diarrhea: return HKObjectType.categoryType(forIdentifier: .diarrhea)
        case .dizziness: return HKObjectType.categoryType(forIdentifier: .dizziness)
        case .drySkin: return HKObjectType.categoryType(forIdentifier: .drySkin)
        case .fainting: return HKObjectType.categoryType(forIdentifier: .fainting)
        case .fatigue: return HKObjectType.categoryType(forIdentifier: .fatigue)
        case .fever: return HKObjectType.categoryType(forIdentifier: .fever)
        case .generalizedBodyAche: return HKObjectType.categoryType(forIdentifier: .generalizedBodyAche)
        case .hairLoss: return HKObjectType.categoryType(forIdentifier: .hairLoss)
        case .headache: return HKObjectType.categoryType(forIdentifier: .headache)
        case .heartburn: return HKObjectType.categoryType(forIdentifier: .heartburn)
        case .hotFlashes: return HKObjectType.categoryType(forIdentifier: .hotFlashes)
        case .lossOfSmell: return HKObjectType.categoryType(forIdentifier: .lossOfSmell)
        case .lossOfTaste: return HKObjectType.categoryType(forIdentifier: .lossOfTaste)
        case .lowerBackPain: return HKObjectType.categoryType(forIdentifier: .lowerBackPain)
        case .memoryLapse: return HKObjectType.categoryType(forIdentifier: .memoryLapse)
        case .moodChanges: return HKObjectType.categoryType(forIdentifier: .moodChanges)
        case .nausea: return HKObjectType.categoryType(forIdentifier: .nausea)
        case .nightSweats: return HKObjectType.categoryType(forIdentifier: .nightSweats)
        case .pelvicPain: return HKObjectType.categoryType(forIdentifier: .pelvicPain)
        case .rapidPoundingOrFlutteringHeartbeat: return HKObjectType.categoryType(forIdentifier: .rapidPoundingOrFlutteringHeartbeat)
        case .runnyNose: return HKObjectType.categoryType(forIdentifier: .runnyNose)
        case .shortnessOfBreath: return HKObjectType.categoryType(forIdentifier: .shortnessOfBreath)
        case .sinusCongestion: return HKObjectType.categoryType(forIdentifier: .sinusCongestion)
        case .skippedHeartbeat: return HKObjectType.categoryType(forIdentifier: .skippedHeartbeat)
        case .sleepChanges: return HKObjectType.categoryType(forIdentifier: .sleepChanges)
        case .soreThroat: return HKObjectType.categoryType(forIdentifier: .soreThroat)
        case .vaginalDryness: return HKObjectType.categoryType(forIdentifier: .vaginalDryness)
        case .vomiting: return HKObjectType.categoryType(forIdentifier: .vomiting)
        case .wheezing: return HKObjectType.categoryType(forIdentifier: .wheezing)
        case .menstrualFlow: return HKObjectType.categoryType(forIdentifier: .menstrualFlow)
        case .intermenstrualBleeding: return HKObjectType.categoryType(forIdentifier: .intermenstrualBleeding)
        case .infrequentMenstrualCycles: return HKObjectType.categoryType(forIdentifier: .infrequentMenstrualCycles)
        case .irregularMenstrualCycles: return HKObjectType.categoryType(forIdentifier: .irregularMenstrualCycles)
        case .persistentIntermenstrualBleeding: return HKObjectType.categoryType(forIdentifier: .persistentIntermenstrualBleeding)
        case .prolongedMenstrualPeriods: return HKObjectType.categoryType(forIdentifier: .prolongedMenstrualPeriods)
        case .ovulationTestResult: return HKObjectType.categoryType(forIdentifier: .ovulationTestResult)
        case .pregnancyTestResult: return HKObjectType.categoryType(forIdentifier: .pregnancyTestResult)
        case .progesteroneTestResult: return HKObjectType.categoryType(forIdentifier: .progesteroneTestResult)
        case .sexualActivity: return HKObjectType.categoryType(forIdentifier: .sexualActivity)
        case .cervicalMucusQuality: return HKObjectType.categoryType(forIdentifier: .cervicalMucusQuality)
        case .contraceptive: return HKObjectType.categoryType(forIdentifier: .contraceptive)
        case .lactation: return HKObjectType.categoryType(forIdentifier: .lactation)
        case .bleedingAfterPregnancy: return HKObjectType.categoryType(forIdentifier: .bleedingAfterPregnancy)
        case .bleedingDuringPregnancy: return HKObjectType.categoryType(forIdentifier: .bleedingDuringPregnancy)
        case .handwashingEvent: return HKObjectType.categoryType(forIdentifier: .handwashingEvent)
        case .toothbrushingEvent: return HKObjectType.categoryType(forIdentifier: .toothbrushingEvent)
        case .environmentalAudioExposureEvent: return HKObjectType.categoryType(forIdentifier: .environmentalAudioExposureEvent)
        case .headphoneAudioExposureEvent: return HKObjectType.categoryType(forIdentifier: .headphoneAudioExposureEvent)
        case .lowCardioFitnessEvent: return HKObjectType.categoryType(forIdentifier: .lowCardioFitnessEvent)
        case .appleWalkingSteadinessEvent: return HKObjectType.categoryType(forIdentifier: .appleWalkingSteadinessEvent)
        case .appleStandHour: return HKObjectType.categoryType(forIdentifier: .appleStandHour)
        case .basalBodyTemperature: return HKObjectType.quantityType(forIdentifier: .basalBodyTemperature)
        case .bloodAlcoholContent: return HKObjectType.quantityType(forIdentifier: .bloodAlcoholContent)
        case .electrodermalActivity: return HKObjectType.quantityType(forIdentifier: .electrodermalActivity)
        case .environmentalSoundReduction: return HKObjectType.quantityType(forIdentifier: .environmentalSoundReduction)
        case .forcedExpiratoryVolume1: return HKObjectType.quantityType(forIdentifier: .forcedExpiratoryVolume1)
        case .forcedVitalCapacity: return HKObjectType.quantityType(forIdentifier: .forcedVitalCapacity)
        case .peakExpiratoryFlowRate: return HKObjectType.quantityType(forIdentifier: .peakExpiratoryFlowRate)
        case .inhalerUsage: return HKObjectType.quantityType(forIdentifier: .inhalerUsage)
        case .insulinDelivery: return HKObjectType.quantityType(forIdentifier: .insulinDelivery)
        case .nikeFuel: return HKObjectType.quantityType(forIdentifier: .nikeFuel)
        case .sixMinuteWalkTestDistance: return HKObjectType.quantityType(forIdentifier: .sixMinuteWalkTestDistance)
        case .appleWalkingSteadiness: return HKObjectType.quantityType(forIdentifier: .appleWalkingSteadiness)
        case .uvExposure: return HKObjectType.quantityType(forIdentifier: .uvExposure)
        case .appleMoveTime: return HKObjectType.quantityType(forIdentifier: .appleMoveTime)
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

    // MARK: - UI categorization

    /// Top-level grouping for the data-type picker UI. With 178 cases a flat
    /// toggle list is unusable; categories let the UI render collapsible groups.
    var category: Category {
        switch self {
        case .steps, .distanceWalkingRunning, .distanceCycling, .activeEnergyBurned,
             .basalEnergyBurned, .exerciseTime, .standHours, .flightsClimbed, .workouts,
             .appleStandHour, .appleMoveTime,
             .runningGroundContactTime, .runningStrideLength, .runningVerticalOscillation,
             .runningPower, .runningSpeed,
             .cyclingCadence, .cyclingPower, .cyclingSpeed, .cyclingFunctionalThresholdPower,
             .distanceSwimming, .swimmingStrokeCount,
             .distanceDownhillSnowSports, .distanceWheelchair, .pushCount,
             .underwaterDepth, .waterTemperature, .nikeFuel, .physicalEffort:
            return .activity

        case .heartRate, .restingHeartRate, .walkingHeartRateAverage, .heartRateVariability,
             .heartRateRecoveryOneMinute, .bloodPressureSystolic, .bloodPressureDiastolic,
             .bloodOxygen, .peripheralPerfusionIndex, .vo2Max, .atrialFibrillationBurden,
             .irregularHeartRhythmEvent, .highHeartRateEvent, .lowHeartRateEvent,
             .lowCardioFitnessEvent:
            return .cardiovascular

        case .weight, .height, .bodyMassIndex, .bodyFatPercentage, .leanBodyMass,
             .waistCircumference, .bodyTemperature, .basalBodyTemperature, .wristTemperature,
             .electrodermalActivity:
            return .bodyMeasurements

        case .sleepAnalysis, .sleepInBed, .sleepAsleep, .sleepAwake, .sleepREM,
             .sleepCore, .sleepDeep:
            return .sleep

        case .dietaryEnergyConsumed, .dietaryWater, .dietaryCaffeine, .dietaryProtein,
             .dietaryFatTotal, .dietaryFatSaturated, .dietaryFatPolyunsaturated,
             .dietaryFatMonounsaturated, .dietaryCholesterol, .dietaryCarbohydrates,
             .dietaryFiber, .dietarySugar, .dietarySodium, .dietaryCalcium, .dietaryIron,
             .dietaryMagnesium, .dietaryPotassium, .dietaryZinc, .dietaryPhosphorus,
             .dietaryIodine, .dietarySelenium, .dietaryCopper, .dietaryManganese,
             .dietaryChromium, .dietaryMolybdenum, .dietaryChloride, .dietaryVitaminA,
             .dietaryVitaminB6, .dietaryVitaminB12, .dietaryVitaminC, .dietaryVitaminD,
             .dietaryVitaminE, .dietaryVitaminK, .dietaryRiboflavin, .dietaryThiamin,
             .dietaryNiacin, .dietaryFolate, .dietaryBiotin, .dietaryPantothenicAcid:
            return .nutrition

        case .abdominalCramps, .acne, .appetiteChanges, .bladderIncontinence, .bloating,
             .breastPain, .chestTightnessOrPain, .chills, .constipation, .coughing,
             .diarrhea, .dizziness, .drySkin, .fainting, .fatigue, .fever,
             .generalizedBodyAche, .hairLoss, .headache, .heartburn, .hotFlashes,
             .lossOfSmell, .lossOfTaste, .lowerBackPain, .memoryLapse, .moodChanges,
             .nausea, .nightSweats, .pelvicPain, .rapidPoundingOrFlutteringHeartbeat,
             .runnyNose, .shortnessOfBreath, .sinusCongestion, .skippedHeartbeat,
             .sleepChanges, .soreThroat, .vaginalDryness, .vomiting, .wheezing:
            return .symptoms

        case .menstrualFlow, .intermenstrualBleeding, .infrequentMenstrualCycles,
             .irregularMenstrualCycles, .persistentIntermenstrualBleeding,
             .prolongedMenstrualPeriods, .ovulationTestResult, .pregnancyTestResult,
             .progesteroneTestResult, .sexualActivity, .cervicalMucusQuality,
             .contraceptive, .lactation, .bleedingAfterPregnancy, .bleedingDuringPregnancy:
            return .reproductiveHealth

        case .mindfulMinutes:
            return .mentalHealth

        case .walkingSpeed, .walkingStepLength, .walkingAsymmetryPercentage,
             .walkingDoubleSupportPercentage, .stairAscentSpeed, .stairDescentSpeed,
             .sixMinuteWalkTestDistance, .appleWalkingSteadiness, .appleWalkingSteadinessEvent,
             .environmentalAudioExposure, .headphoneAudioExposure,
             .environmentalAudioExposureEvent, .headphoneAudioExposureEvent,
             .environmentalSoundReduction:
            return .mobilityAndHearing

        case .respiratoryRate, .forcedExpiratoryVolume1, .forcedVitalCapacity,
             .peakExpiratoryFlowRate, .inhalerUsage, .bloodGlucose, .insulinDelivery:
            return .respiratoryAndMetabolic

        case .timeInDaylight, .uvExposure, .handwashingEvent, .toothbrushingEvent,
             .numberOfTimesFallen, .numberOfAlcoholicBeverages, .bloodAlcoholContent:
            return .lifestyle
        }
    }

    /// Sensitive types are off by default and must be enabled deliberately.
    /// Includes reproductive health, alcohol, mental-health symptoms, and
    /// medical-grade cardiac alerts whose presence is itself diagnostic.
    var isSensitive: Bool {
        switch self {
        case .menstrualFlow, .intermenstrualBleeding, .infrequentMenstrualCycles,
             .irregularMenstrualCycles, .persistentIntermenstrualBleeding,
             .prolongedMenstrualPeriods, .ovulationTestResult, .pregnancyTestResult,
             .progesteroneTestResult, .sexualActivity, .cervicalMucusQuality,
             .contraceptive, .lactation, .bleedingAfterPregnancy, .bleedingDuringPregnancy,
             .moodChanges, .memoryLapse, .sleepChanges, .appetiteChanges,
             .numberOfAlcoholicBeverages, .bloodAlcoholContent,
             .irregularHeartRhythmEvent, .highHeartRateEvent, .lowHeartRateEvent:
            return true
        default:
            return false
        }
    }

    /// Default-enabled set for first launch: every non-sensitive type. The user
    /// gets a ready-to-sync experience covering the full standard health profile
    /// (activity, vitals, sleep, body, nutrition, symptoms, mobility, hearing,
    /// spirometry, lifestyle). Sensitive categories — reproductive health,
    /// mental-health symptoms, alcohol, medical-grade cardiac event alerts —
    /// stay off until the user explicitly opts in via the picker.
    ///
    /// Rationale: this is a sync tool to the user's own destinations (their
    /// Mac, their iCloud folder, their files). It is not data sharing with a
    /// third party. Defaulting to "mirror everything except the truly intimate"
    /// matches the actual mental model and minimizes setup friction.
    static let defaultEnabled: Set<HealthDataType> = {
        Set(HealthDataType.allCases.filter { !$0.isSensitive })
    }()

    var isDefaultEnabled: Bool { Self.defaultEnabled.contains(self) }

    enum Category: String, CaseIterable, Sendable {
        case activity
        case cardiovascular
        case bodyMeasurements
        case sleep
        case nutrition
        case symptoms
        case reproductiveHealth
        case mentalHealth
        case mobilityAndHearing
        case respiratoryAndMetabolic
        case lifestyle

        var displayName: String {
            switch self {
            case .activity:                 return "Activity & Workouts"
            case .cardiovascular:           return "Cardiovascular"
            case .bodyMeasurements:         return "Body Measurements"
            case .sleep:                    return "Sleep"
            case .nutrition:                return "Nutrition"
            case .symptoms:                 return "Symptoms"
            case .reproductiveHealth:       return "Reproductive Health"
            case .mentalHealth:             return "Mental Health"
            case .mobilityAndHearing:       return "Mobility & Hearing"
            case .respiratoryAndMetabolic:  return "Respiratory & Metabolic"
            case .lifestyle:                return "Lifestyle"
            }
        }

        var iconSystemName: String {
            switch self {
            case .activity:                 return "figure.run"
            case .cardiovascular:           return "heart.fill"
            case .bodyMeasurements:         return "scalemass.fill"
            case .sleep:                    return "bed.double.fill"
            case .nutrition:                return "fork.knife"
            case .symptoms:                 return "thermometer"
            case .reproductiveHealth:       return "drop.fill"
            case .mentalHealth:             return "brain.head.profile"
            case .mobilityAndHearing:       return "ear.fill"
            case .respiratoryAndMetabolic:  return "lungs.fill"
            case .lifestyle:                return "sun.max.fill"
            }
        }

        /// Categories that open by default. Most are collapsed to keep the
        /// screen scannable.
        var defaultExpanded: Bool {
            switch self {
            case .activity, .cardiovascular, .sleep:
                return true
            default:
                return false
            }
        }
    }

    /// Quick-configuration presets for common personas. Applying a preset
    /// replaces the entire enabled set with the preset's curated types.
    enum Preset: String, CaseIterable, Sendable {
        case general
        case athlete
        case cycleTracking
        case conditionsMonitoring

        var displayName: String {
            switch self {
            case .general:                  return "General Wellness"
            case .athlete:                  return "Athlete"
            case .cycleTracking:            return "Cycle Tracking"
            case .conditionsMonitoring:     return "Health Conditions"
            }
        }

        var iconSystemName: String {
            switch self {
            case .general:                  return "heart.text.square"
            case .athlete:                  return "figure.run.circle.fill"
            case .cycleTracking:            return "calendar.badge.clock"
            case .conditionsMonitoring:     return "stethoscope"
            }
        }

        var types: Set<HealthDataType> {
            switch self {
            case .general:
                return HealthDataType.defaultEnabled
            case .athlete:
                let athleteCats: Set<HealthDataType.Category> = [.activity, .cardiovascular, .sleep, .mobilityAndHearing]
                return Set(HealthDataType.allCases.filter { athleteCats.contains($0.category) && !$0.isSensitive })
            case .cycleTracking:
                return Set(HealthDataType.allCases.filter { $0.category == .reproductiveHealth })
                    .union([.basalBodyTemperature, .heartRate, .sleepAnalysis,
                            .moodChanges, .breastPain, .pelvicPain, .hotFlashes])
            case .conditionsMonitoring:
                return [
                    .heartRate, .restingHeartRate, .heartRateVariability,
                    .bloodPressureSystolic, .bloodPressureDiastolic, .bloodOxygen,
                    .atrialFibrillationBurden, .irregularHeartRhythmEvent,
                    .highHeartRateEvent, .lowHeartRateEvent,
                    .bloodGlucose, .insulinDelivery,
                    .forcedExpiratoryVolume1, .forcedVitalCapacity,
                    .peakExpiratoryFlowRate, .inhalerUsage,
                    .bodyTemperature, .basalBodyTemperature
                ]
            }
        }
    }
}
