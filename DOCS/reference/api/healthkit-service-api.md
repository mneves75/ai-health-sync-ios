# HealthKitService API

**Actor-based thread-safe HealthKit data access**

---

## Overview

`HealthKitService` is an actor that provides safe, concurrent access to Apple HealthKit data. It handles authorization, data fetching, and pagination while preventing data races through actor isolation.

**Type:** Actor
**Module:** Services/HealthKit
**Availability:** iOS 17.0+
**Thread Safety:** Guaranteed by actor isolation

---

## Declaration

```swift
actor HealthKitService: HealthDataProviding
```

---

## Topics

### Initialization

### `init(store:)`

Initialize the HealthKit service with a custom store (for testing).

```swift
init(store: HealthStoreProtocol = HKHealthStore())
```

**Parameters:**
- `store` - A HealthKit store instance (defaults to `HKHealthStore()`)

**Discussion:**
The store parameter is primarily for dependency injection in tests. Production code should use the default value.

---

### Availability

### `isAvailable()`

Check if HealthKit is available on the current device.

```swift
func isAvailable() -> Bool
```

**Returns:** `true` if HealthKit is available, `false` otherwise

**Discussion:**
HealthKit requires iOS 17+ and is not available on iPad or Mac.

---

### Authorization

### `requestAuthorization(for:)`

Request HealthKit read permissions for specified data types.

```swift
func requestAuthorization(for types: [HealthDataType]) async throws -> Bool
```

**Parameters:**
- `types` - Array of health data types to access

**Returns:** `true` if authorization was requested successfully

**Throws:** `Error` if authorization request fails

**Important Notes:**
- HealthKit authorization is **one-time only**. Users can only change permissions in Settings > Health > Data Access & Devices
- The return value indicates whether the prompt was shown, not whether user granted access
- For privacy reasons, Apple intentionally hides whether users granted or denied read access
- This method uses `withCheckedThrowingContinuation` to wrap the callback-based HealthKit API

**Example:**
```swift
let service = HealthKitService()
let types: [HealthDataType] = [.steps, .heartRate]

do {
    let success = try await service.requestAuthorization(for: types)
    print("Authorization requested: \(success)")
} catch {
    print("Authorization failed: \(error)")
}
```

### `hasRequestedAuthorization(for:)`

Check whether we've already requested HealthKit permissions.

```swift
func hasRequestedAuthorization(for types: [HealthDataType]) async -> Bool
```

**Parameters:**
- `types` - Array of health data types to check

**Returns:** `true` if the authorization dialog has already been shown to the user

**Discussion:**
- Returns `true` even if user denied access (it only checks if we asked)
- Returns `false` if we haven't asked yet
- Use this to avoid showing the authorization prompt unnecessarily

---

### Data Fetching

### `fetchSamples(types:startDate:endDate:limit:offset:)`

Fetch health samples from HealthKit with pagination support.

```swift
func fetchSamples(
    types: [HealthDataType],
    startDate: Date,
    endDate: Date,
    limit: Int,
    offset: Int
) async -> HealthDataResponse
```

**Parameters:**
- `types` - Health data types to fetch (e.g., steps, heart rate, sleep)
- `startDate` - Beginning of date range (inclusive)
- `endDate` - End of date range (inclusive)
- `limit` - Maximum number of samples to return (capped at 10,000)
- `offset` - Number of samples to skip (for pagination)

**Returns:** `HealthDataResponse` containing fetched samples and metadata

**Response Properties:**
- `status: Status` - `.ok` or `.error`
- `samples: [HealthSampleDTO]` - Array of health samples
- `message: String?` - Error message if status is `.error`
- `hasMore: Bool` - Whether more samples are available
- `returnedCount: Int` - Number of samples actually returned

**Behavior:**
- Fetches data from HealthKit for each specified type
- Sorts all samples by date (most recent first)
- Applies offset and limit for pagination
- Caps results at 10,000 samples to prevent memory exhaustion
- Returns empty results if: no permission, no data in range, or user has no recorded data

**Real-World Notes:**
- The service does NOT check authorization status before fetching
- This is intentional: Apple hides read authorization status for privacy
- Instead, we attempt to fetch - empty results could mean no permission OR no data
- This is Apple's recommended approach for read-only health apps

**Example:**
```swift
let service = HealthKitService()

let now = Date()
let yesterday = now.addingTimeInterval(-24 * 60 * 60)

let response = await service.fetchSamples(
    types: [.steps, .heartRate],
    startDate: yesterday,
    endDate: now,
    limit: 100,
    offset: 0
)

switch response.status {
case .ok:
    print("Fetched \(response.returnedCount) samples")
    for sample in response.samples {
        print("\(sample.type): \(sample.value) \(sample.unit)")
    }

    if response.hasMore {
        print("More samples available - fetch next page")
    }
case .error:
    print("Error: \(response.message ?? "Unknown error")")
}
```

---

### Implementation Details

#### Actor Isolation

All methods are actor-isolated, meaning:
- Only one task can access the actor's state at a time
- No risk of data races when accessing from multiple concurrent tasks
- Methods must be called with `await` from outside the actor

#### Memory Management

- Maximum 10,000 samples per request to prevent memory exhaustion
- Efficient pagination using offset/limit
- Samples are sorted in-memory (HealthKit doesn't support server-side sorting)

#### Privacy-First Design

The service follows Apple's privacy guidelines:
- Does NOT check if user granted read access (intentionally impossible)
- Treats "denied access" and "no data" identically (both return empty results)
- Respects user privacy by not attempting to detect authorization status

---

### Relationships

**Conforms To:**
- `HealthDataProviding` protocol

**Dependencies:**
- `HealthStoreProtocol` - Abstraction over `HKHealthStore`
- `HealthSampleMapper` - Converts `HKSample` to `HealthSampleDTO`
- `AppLoggers.health` - Structured logging

**Used By:**
- `NetworkServer` - Provides health data for API responses
- SwiftUI views - Display health data in UI

---

### Error Handling

The service handles errors gracefully:

| Error Scenario | Response |
|----------------|----------|
| HealthKit not available | `status: .error`, message: "Health data is unavailable" |
| No valid data types | `status: .error`, message: "No valid health data types" |
| Empty results | `status: .ok`, empty samples array |
| Query failure | Logs error, returns empty samples |
| Memory limit | Caps at 10,000 samples |

---

### Performance Characteristics

| Operation | Complexity | Notes |
|-----------|-----------|-------|
| Authorization request | O(1) | One-time prompt |
| Data fetch | O(n × m) | n = types, m = samples per type |
| Sorting | O(n log n) | n = total samples |
| Pagination | O(1) | Uses array slicing |

---

## See Also

- **[HealthDataType Enum](../models/health-data-type.md)** - Available health data types
- **[HealthSampleDTO](../models/health-sample-dto.md)** - Data transfer object
- **[NetworkServer API](./network-server.md)** - How data is served over network
- **[Apple HealthKit Documentation](https://developer.apple.com/documentation/healthkit)** - Official docs

---

## Example: Complete Workflow

```swift
// 1. Create service
let service = HealthKitService()

// 2. Check availability
guard service.isAvailable() else {
    print("HealthKit not available on this device")
    return
}

// 3. Check if we need to request authorization
let types: [HealthDataType] = [.steps, .heartRate, .sleep]
let hasAuth = await service.hasRequestedAuthorization(for: types)

if !hasAuth {
    // Request authorization (one-time prompt)
    try? await service.requestAuthorization(for: types)
}

// 4. Fetch data
let now = Date()
let weekAgo = now.addingTimeInterval(-7 * 24 * 60 * 60)

var allSamples: [HealthSampleDTO] = []
var offset = 0
let limit = 1000

// 5. Paginate through results
repeat {
    let response = await service.fetchSamples(
        types: types,
        startDate: weekAgo,
        endDate: now,
        limit: limit,
        offset: offset
    )

    allSamples.append(contentsOf: response.samples)
    offset += response.returnedCount

    if !response.hasMore {
        break
    }
} while true

print("Fetched \(allSamples.count) total samples")
```

---

**API Documentation Version:** 1.0.0
**Last Updated:** 2026-01-07
**Based on:** iOS Health Sync App v1.0.0
