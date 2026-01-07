# Chapter 6: Working with HealthKit

**Accessing Apple Health Data**

---

## Learning Objectives

After this chapter, you will be able to:

- ✅ Understand HealthKit permissions
- ✅ Request authorization
- ✅ Query health data
- ✅ Map HealthKit objects to DTOs
- ✅ Handle privacy requirements

---

## The Simple Explanation

### What Is HealthKit?

**HealthKit** is Apple's framework for storing and accessing health data.

Think of it as a **secure vault** for health information:

```
┌─────────────────────────────────────┐
│         HealthKit Vault             │
│                                     │
│  🔒 Encrypted at rest               │
│  🔒 Protected by passcode/biometrics│
│  🔒 User controls access            │
│  🔒 Apps can't see everything       │
└─────────────────────────────────────┘
         ↑                ↑
    User grants       Apps request
    permission         specific access
```

### What HealthKit Stores

| Category | Examples |
|----------|----------|
| **Activity** | Steps, distance, energy burned |
| **Vitals** | Heart rate, blood pressure, temperature |
| **Sleep** | Sleep analysis, time in bed |
| **Body** | Weight, height, BMI |
| **Workouts** | Exercise type, duration, distance |
| **Mobility** | Walking speed, step length |
| **Nutrition** | Dietary intake, water |
| **Mindfulness** | Meditation time |

---

## Permissions Model

### The Privacy-First Design

**Apple intentionally hides user decisions:**

```
For READ permissions:
┌─────────────────────────────────────┐
│ User sees authorization dialog      │
│ [Allow] [Deny]                      │
└─────────────────────────────────────┘
         ↓
┌─────────────────────────────────────┐
│ App CANNOT know which button pressed│
│ - If "Deny": query returns empty    │
│ - If "Allow": query returns data    │
│ - No way to tell the difference!    │
└─────────────────────────────────────┘
```

**Why?** Prevents apps from nagging users:

```swift
// ❌ Apps can't do this:
if userDeniedPermission {
    nagUserToEnable()  // Can't detect denial!
}
```

### Request Types

**Read vs Write:**

```swift
// READ: See existing data
let readTypes: Set<HKObjectType> = [
    HKObjectType.quantityType(forIdentifier: .stepCount)!,
    HKObjectType.quantityType(forIdentifier: .heartRate)!
]

// WRITE: Create new data
let writeTypes: Set<HKSampleType> = [
    HKObjectType.quantityType(forIdentifier: .stepCount)!
]

// Our app is READ-ONLY!
store.requestAuthorization(toShare: nil, read: readTypes) { ... }
```

**Why read-only?**
- We're exporting data, not creating it
- Less permission friction
- More trust from users
- Simpler code

---

## In Our Code: HealthKitService

**File:** `Services/HealthKit/HealthKitService.swift`

### Service Structure

```swift
protocol HealthDataProviding: Sendable {
    func fetchSamples(types: [HealthDataType], startDate: Date, endDate: Date,
                     limit: Int, offset: Int) async -> HealthDataResponse
}

actor HealthKitService {
    private let store: HealthStoreProtocol

    init(store: HealthStoreProtocol = HKHealthStore()) {
        self.store = store
    }
}
```

**Key design:**
- `actor` = Thread-safe
- `protocol` = Testable
- `HealthStoreProtocol` = Mockable

### Checking Availability

```swift
// File: Services/HealthKit/HealthKitService.swift:19-21
func isAvailable() -> Bool {
    HKHealthStore.isHealthDataAvailable()
}
```

**When is HealthKit unavailable?**
- iPad (some models)
- Devices without health sensors
- Devices with restrictions

### Requesting Authorization

```swift
// File: Services/HealthKit/HealthKitService.swift:23-34
func requestAuthorization(for types: [HealthDataType]) async throws -> Bool {
    let readTypes = Set(await MainActor.run {
        types.compactMap { $0.sampleType }
    })

    return try await withCheckedThrowingContinuation { continuation in
        store.requestAuthorization(toShare: [], read: readTypes) {
            success, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }
            continuation.resume(returning: success)
        }
    }
}
```

**Breaking it down:**

1. **Get HKSampleTypes from our enum:**
```swift
let readTypes = Set(await MainActor.run {
    types.compactMap { $0.sampleType }
})
```

2. **Bridge callback to async/await:**
```swift
return try await withCheckedThrowingContinuation { continuation in
    store.requestAuthorization(...) { success, error in
        // Resume with result
    }
}
```

3. **Read-only:**
```swift
toShare: [],  // No write permissions
read: readTypes  // Only read
```

### Checking Authorization Status

```swift
// File: Services/HealthKit/HealthKitService.swift:49-65
func hasRequestedAuthorization(for types: [HealthDataType]) async -> Bool {
    let readTypes = Set(await MainActor.run {
        types.compactMap { $0.sampleType as? HKObjectType }
    })
    guard !readTypes.isEmpty else { return false }

    return await withCheckedContinuation { continuation in
        store.getRequestStatusForAuthorization(toShare: [], read: readTypes) {
            status, error in
            if let error {
                AppLoggers.health.error("Failed to check authorization status")
                continuation.resume(returning: false)
                return
            }
            // .unnecessary = user already saw the dialog
            continuation.resume(returning: status == .unnecessary)
        }
    }
}
```

**Status meanings:**
- `.notDetermined` = Never asked
- `.shouldRequest` = Should ask user
- `.unnecessary` = Already asked

**Important:** This doesn't tell us if user said YES or NO, just if we ASKED.

---

## Querying Health Data

### The Query Flow

```
1. Create HKSampleType
       ↓
2. Create NSPredicate (filters)
       ↓
3. Create HKQuery
       ↓
4. Execute query on HKHealthStore
       ↓
5. Receive results in callback
       ↓
6. Map to DTO
```

### Fetch Samples

**File:** `Services/HealthKit/HealthKitService.swift:70-114`

```swift
func fetchSamples(types: [HealthDataType], startDate: Date, endDate: Date,
                 limit: Int, offset: Int) async -> HealthDataResponse {
    guard isAvailable() else {
        return HealthDataResponse(status: .error, samples: [],
                                  message: "Health data is unavailable",
                                  hasMore: false, returnedCount: 0)
    }

    let requestedTypes = await MainActor.run {
        types.compactMap { $0.sampleType }
    }
    guard !requestedTypes.isEmpty else {
        return HealthDataResponse(status: .error, samples: [],
                                  message: "No valid health data types",
                                  hasMore: false, returnedCount: 0)
    }

    // NOTE: We DON'T check authorization here
    // Apple hides that info for privacy
    // We just try to fetch

    let effectiveLimit = min(limit, Self.maxSamplesPerRequest)
    let predicate = HKQuery.predicateForSamples(
        withStart: startDate,
        end: endDate,
        options: .strictStartDate
    )

    var collected: [HealthSampleDTO] = []
    for type in types {
        let sampleType = await MainActor.run { type.sampleType }
        guard let sampleType else { continue }

        let samples = await querySamples(
            for: type,
            sampleType: sampleType,
            predicate: predicate,
            limit: effectiveLimit + offset + 1
        )
        collected.append(contentsOf: samples)
    }

    // Sort, paginate, return
    let sorted = collected.sorted { $0.startDate > $1.startDate }
    let afterOffset = Array(sorted.dropFirst(offset))
    let hasMore = afterOffset.count > effectiveLimit
    let paginated = Array(afterOffset.prefix(effectiveLimit))

    return HealthDataResponse(status: .ok, samples: paginated,
                              message: nil, hasMore: hasMore,
                              returnedCount: paginated.count)
}
```

**Key points:**
1. **Cap limit** to prevent memory exhaustion
2. **Don't check auth** - just query (privacy design)
3. **Sort** by date (newest first)
4. **Paginate** with offset/limit
5. **Fetch one extra** to detect `hasMore`

### Query Implementation

**File:** `Services/HealthKit/HealthKitService.swift:116-134`

```swift
private func querySamples(for type: HealthDataType, sampleType: HKSampleType,
                         predicate: NSPredicate, limit: Int) async -> [HealthSampleDTO] {
    await withCheckedContinuation { continuation in
        let sort = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        let query = HKSampleQuery(
            sampleType: sampleType,
            predicate: predicate,
            limit: limit,
            sortDescriptors: [sort]
        ) { _, results, error in
            if let error {
                AppLoggers.health.error("HealthKit query failed")
                continuation.resume(returning: [])
                return
            }

            let samples = results?.compactMap { sample in
                HealthSampleMapper.mapSample(sample, requestedType: type)
            } ?? []

            continuation.resume(returning: samples)
        }

        store.execute(query)
    }
}
```

---

## Health Data Types

### Our Enum

**File:** `Core/Models/HealthDataType.swift`

```swift
enum HealthDataType: String, CaseIterable, Codable, Sendable, Identifiable {
    case steps
    case distanceWalkingRunning
    case distanceCycling
    case activeEnergyBurned
    // ... 35+ total types

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .heartRate: return "Heart Rate"
        // ...
        }
    }

    var sampleType: HKSampleType? {
        switch self {
        case .steps:
            return HKObjectType.quantityType(forIdentifier: .stepCount)
        case .heartRate:
            return HKObjectType.quantityType(forIdentifier: .heartRate)
        // ...
        }
    }
}
```

**Why an enum?**
- Type-safe (no typos)
- Easy to iterate
- Codable for JSON
- Identifiable for SwiftUI

---

## Mapping HealthKit to DTOs

### The Mapper

**File:** `Services/HealthKit/HealthSampleMapper.swift`

```swift
enum HealthSampleMapper {
    static func mapSample(_ sample: HKSample, requestedType: HealthDataType) -> HealthSampleDTO? {
        guard let quantitySample = sample as? HKQuantitySample else {
            // Handle workouts, categories, etc.
            return mapWorkout(sample as? HKWorkout, requestedType: requestedType)
        }

        let unit = preferredUnit(for: requestedType)
        let value = quantitySample.quantity.doubleValue(for: unit)

        return HealthSampleDTO(
            id: sample.uuid,
            type: requestedType.rawValue,
            value: value,
            unit: unit.unitString,
            startDate: sample.startDate,
            endDate: sample.endDate,
            sourceName: sample.sourceRevision.source.name,
            metadata: sample.metadata
        )
    }
}
```

**Why DTOs?**
- Decoupled from HealthKit
- JSON-serializable
- No dependencies on HK types
- Easy to test

---

## Privacy Requirements

### No PII in Logs

```swift
// ❌ WRONG: Logging health data
AppLoggers.health.info("Heart rate: \(heartRate)")

// ✅ RIGHT: Omit or hash
AppLoggers.health.info("Processed heart rate sample")
AppLoggers.health.info("User ID: \(hashUserID(userID))")
```

### No Data Inference

```swift
// ❌ WRONG: Trying to detect denial
if samples.isEmpty {
    showMessage("Please enable health access")  // Don't do this!
}

// ✅ RIGHT: Treat empty as valid
if samples.isEmpty {
    showMessage("No data found in this date range")
}
```

### Entitlements

**File:** `Resources/HealthSync.entitlements`

```xml
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.healthkit.access</key>
<array/>
```

### Info.plist

```xml
<key>NSHealthShareUsageDescription</key>
<string>This app needs access to your health data to export it to your Mac.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>This app does not write health data.</string>
```

---

## Exercises

### 🟢 Beginner: Create a Health Data Type

**Task:** Add a new health data type to the enum:

```swift
enum HealthDataType {
    // Add: bloodGlucose
    // displayName: "Blood Glucose"
    // identifier: .bloodGlucose
}
```

---

### 🟡 Intermediate: Query with Date Range

**Task:** Fetch steps from the last 7 days:

```swift
let now = Date()
let sevenDaysAgo = // Your code here

let response = await healthService.fetchSamples(
    types: [.steps],
    startDate: sevenDaysAgo,
    endDate: now,
    limit: 1000,
    offset: 0
)
```

---

### 🔴 Advanced: Custom Query

**Task:** Create a query that:
- Filters by source (only Apple Watch)
- Averages heart rate
- Groups by day

```swift
func averageHeartRateByDay(
    startDate: Date,
    endDate: Date
) async -> [Date: Double] {
    // Your implementation
}
```

---

## Common Pitfalls

### Pitfall 1: Assuming authorization means data

```swift
// WRONG:
if hasAuthorization {
    let data = await fetchData()  // Might be empty!
}

// RIGHT:
let data = await fetchData()
if data.isEmpty {
    showMessage("No data available")
}
```

### Pitfall 2: Forgetting MainActor

```swift
// WRONG: HKSampleType off main thread
let type = HKObjectType.quantityType(forIdentifier: .stepCount)!

// RIGHT: On MainActor
let type = await MainActor.run {
    HKObjectType.quantityType(forIdentifier: .stepCount)!
}
```

### Pitfall 3: Not handling units correctly

```swift
// WRONG: Assuming unit
let value = sample.quantity.doubleValue(for: HKUnit.count())

// RIGHT: Use preferred unit
let unit = HKUnit(from: "count/min")  // For heart rate
let value = sample.quantity.doubleValue(for: unit)
```

---

## Key Takeaways

### ✅ HealthKit Patterns

| Pattern | Description |
|---------|-------------|
| **Read-only** | Don't request write permissions |
| **Privacy-first** | Can't detect denial |
| **Type-safe enum** | Map to HKSampleType |
| **DTO mapping** | Decouple from HealthKit |
| **No PII in logs** | Protect user privacy |

---

## Coming Next

In **Chapter 7: Security - Protecting Health Data**, you'll learn:

- Keychain storage
- TLS certificates
- mTLS authentication
- Secure pairing

---

**Next Chapter:** [Security - Protecting Health Data](07-security.md) →
