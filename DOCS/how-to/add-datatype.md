# Add New Data Type: Extend Supported Health Metrics

**Add support for a new HealthKit data type to the iOS app**

---

**Time:** 30 minutes
**Difficulty:** Intermediate
**Prerequisites:**
- [ ] Xcode 26 with project open
- [ ] Understanding of HealthKit data types
- [ ] Familiarity with Swift enums

---

## Goal

Add support for a new HealthKit data type (e.g., blood pressure) to the iOS app and CLI.

---

## Steps

### Step 1: Identify the HealthKit Type

Check Apple's HealthKit documentation for the type identifier:

| Data Type | HKQuantityType | Unit |
|-----------|---------------|------|
| Blood Pressure Systolic | `.bloodPressureSystolic` | mmHg |
| Blood Pressure Diastolic | `.bloodPressureDiastolic` | mmHg |
| Blood Glucose | `.bloodGlucose` | mg/dL |
| Body Temperature | `.bodyTemperature` | degC |

---

### Step 2: Add to HealthDataType Enum

**File:** `iOS Health Sync App/Core/Models/HealthDataType.swift`

```swift
public enum HealthDataType: String, Codable, CaseIterable, Sendable {
    // Existing types
    case steps
    case heartRate
    case activeEnergy
    // ... other existing types

    // Add new type
    case bloodPressureSystolic
    case bloodPressureDiastolic
}
```

---

### Step 3: Add HKQuantityType Mapping

In the same file, add the `sampleType` computed property case:

```swift
extension HealthDataType {
    var sampleType: HKSampleType? {
        switch self {
        // Existing mappings
        case .steps:
            return HKQuantityType(.stepCount)
        case .heartRate:
            return HKQuantityType(.heartRate)

        // Add new type mapping
        case .bloodPressureSystolic:
            return HKQuantityType(.bloodPressureSystolic)
        case .bloodPressureDiastolic:
            return HKQuantityType(.bloodPressureDiastolic)
        }
    }
}
```

---

### Step 4: Add Unit Mapping

Add the unit for the new type:

```swift
extension HealthDataType {
    var unit: HKUnit {
        switch self {
        // Existing units
        case .steps, .flightsClimbed:
            return .count()
        case .heartRate:
            return HKUnit.count().unitDivided(by: .minute())

        // Add new type unit
        case .bloodPressureSystolic, .bloodPressureDiastolic:
            return .millimeterOfMercury()
        }
    }
}
```

---

### Step 5: Add Display Name

Add human-readable display name:

```swift
extension HealthDataType {
    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .heartRate: return "Heart Rate"
        // Add new type display name
        case .bloodPressureSystolic: return "Blood Pressure (Systolic)"
        case .bloodPressureDiastolic: return "Blood Pressure (Diastolic)"
        }
    }
}
```

---

### Step 6: Update HealthSampleMapper

**File:** `iOS Health Sync App/Services/HealthKit/HealthSampleMapper.swift`

Ensure the mapper handles the new type:

```swift
func map(_ sample: HKQuantitySample, type: HealthDataType) -> HealthSampleDTO {
    let value = sample.quantity.doubleValue(for: type.unit)

    return HealthSampleDTO(
        id: sample.uuid.uuidString,
        type: type.rawValue,
        value: value,
        unit: type.unit.unitString,
        timestamp: sample.startDate,
        source: sample.sourceRevision.source.name
    )
}
```

---

### Step 7: Request Authorization

The HealthKitService automatically requests authorization for all types in `HealthDataType.allCases`. Verify the new type is included:

```swift
// In HealthKitService.swift
func requestAuthorization() async throws {
    let types = Set(HealthDataType.allCases.compactMap { $0.sampleType })
    try await healthStore.requestAuthorization(toShare: [], read: types)
}
```

---

### Step 8: Test the New Type

**Build and run the app:**

1. Clean build: **Cmd+Shift+K**
2. Build: **Cmd+B**
3. Run: **Cmd+R**
4. Accept new HealthKit permissions when prompted

**Test via CLI:**

```bash
# Verify type appears
healthsync types

# Fetch data for new type
healthsync fetch --types bloodPressureSystolic
```

---

## Verification

**In iOS Simulator:**

1. Add test data to Health app:
   - Health > Browse > Vitals > Blood Pressure > Add Data
2. Verify data appears in iOS Health Sync app
3. Fetch via CLI

**Expected output:**
```csv
timestamp,type,value,unit,source
2026-01-07T10:30:00Z,bloodPressureSystolic,120,mmHg,Health
```

---

## Common Issues

### Issue: "Type not available"

**Cause:** HKQuantityType doesn't exist for this identifier.

**Solution:**
Check Apple documentation for correct type identifier. Some types require specific iOS versions.

### Issue: "Authorization not requested"

**Cause:** Type not in HealthDataType.allCases.

**Solution:**
Ensure new case is added to enum and marked as `CaseIterable`.

### Issue: "Wrong unit"

**Cause:** Unit mismatch between HealthKit and your mapping.

**Solution:**
Check Apple documentation for correct HKUnit. Common units:
- `.count()` - for counts
- `.kilocalorie()` - for energy
- `.meter()` - for distance
- `.millimeterOfMercury()` - for blood pressure

---

## Adding Category Types (Sleep, etc.)

For category types like sleep stages:

```swift
case sleepAnalysis

var sampleType: HKSampleType? {
    switch self {
    case .sleepAnalysis:
        return HKCategoryType(.sleepAnalysis)
    // ...
    }
}
```

Category types have enum values instead of numeric values:

```swift
func mapCategory(_ sample: HKCategorySample, type: HealthDataType) -> HealthSampleDTO {
    let valueString: String
    if type == .sleepAnalysis {
        let sleepValue = HKCategoryValueSleepAnalysis(rawValue: sample.value)
        valueString = sleepValue?.description ?? "unknown"
    }
    // ...
}
```

---

## Adding Correlation Types (Blood Pressure)

Blood pressure is a correlation of systolic and diastolic:

```swift
case bloodPressure

var sampleType: HKSampleType? {
    switch self {
    case .bloodPressure:
        return HKCorrelationType(.bloodPressure)
    // ...
    }
}
```

Query correlations:

```swift
func fetchBloodPressure() async throws -> [BloodPressureDTO] {
    let type = HKCorrelationType(.bloodPressure)
    let samples = try await healthStore.samples(for: type, predicate: predicate)

    return samples.map { correlation in
        let systolic = correlation.objects(for: HKQuantityType(.bloodPressureSystolic)).first
        let diastolic = correlation.objects(for: HKQuantityType(.bloodPressureDiastolic)).first
        // ...
    }
}
```

---

## See Also

- [HealthKit Guide](../learn/06-healthkit.md) - Complete HealthKit reference
- [Architecture](../reference/architecture.md) - System design
- [Write Tests](./write-tests.md) - Test your changes

---

**Last Updated:** 2026-01-07
