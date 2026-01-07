# Write Tests: Testing iOS Health Sync

**Create unit and integration tests for the iOS app and CLI**

---

**Time:** 30 minutes
**Difficulty:** Intermediate
**Prerequisites:**
- [ ] Xcode 26 with project open
- [ ] Understanding of Swift Testing framework
- [ ] Familiarity with dependency injection

---

## Goal

Write comprehensive tests for iOS Health Sync using Swift Testing framework.

---

## Steps

### Step 1: Understand the Test Structure

```
iOS Health Sync AppTests/
├── BackgroundTaskControllerTests.swift
├── DEREncoderTests.swift
├── HealthKitServiceTests.swift
├── NetworkServerTests.swift
├── PairingClipboardTests.swift
├── QRCodeRendererTests.swift
└── QRCodeViewModelTests.swift

macOS/HealthSyncCLI/Tests/
└── HealthSyncCLITests/
    └── CommandTests.swift
```

---

### Step 2: Write a Basic Test

**File:** `iOS Health Sync AppTests/ExampleTests.swift`

```swift
import Testing
@testable import iOS_Health_Sync_App

struct ExampleTests {

    @Test func basicAddition() {
        let result = 2 + 2
        #expect(result == 4)
    }

    @Test func stringContains() {
        let greeting = "Hello, World!"
        #expect(greeting.contains("World"))
    }
}
```

---

### Step 3: Test a Service with Mock

**File:** `iOS Health Sync AppTests/HealthKitServiceTests.swift`

```swift
import Testing
import HealthKit
@testable import iOS_Health_Sync_App

// Mock HealthStore
final class MockHealthStore: HealthStoreProtocol {
    var authorizationStatus: HKAuthorizationStatus = .sharingAuthorized
    var mockSamples: [HKSample] = []

    func requestAuthorization(
        toShare: Set<HKSampleType>,
        read: Set<HKObjectType>
    ) async throws {
        // Mock implementation
    }

    func samples(
        for type: HKSampleType,
        predicate: NSPredicate?
    ) async throws -> [HKSample] {
        return mockSamples
    }
}

struct HealthKitServiceTests {

    @Test func requestAuthorization() async throws {
        // Arrange
        let mockStore = MockHealthStore()
        let service = HealthKitService(healthStore: mockStore)

        // Act
        let authorized = try await service.requestAuthorization(
            for: [.steps, .heartRate]
        )

        // Assert
        #expect(authorized == true)
    }

    @Test func fetchSamplesReturnsData() async throws {
        // Arrange
        let mockStore = MockHealthStore()
        mockStore.mockSamples = createMockSamples(count: 5)
        let service = HealthKitService(healthStore: mockStore)

        // Act
        let samples = try await service.fetchSamples(
            type: .steps,
            startDate: Date().addingTimeInterval(-86400),
            endDate: Date()
        )

        // Assert
        #expect(samples.count == 5)
    }

    @Test func fetchSamplesEmptyRange() async throws {
        let mockStore = MockHealthStore()
        mockStore.mockSamples = []
        let service = HealthKitService(healthStore: mockStore)

        let samples = try await service.fetchSamples(
            type: .steps,
            startDate: Date(),
            endDate: Date()
        )

        #expect(samples.isEmpty)
    }
}
```

---

### Step 4: Test Async Code

```swift
@Test func asyncOperation() async throws {
    let service = MyAsyncService()

    // Async call
    let result = try await service.fetchData()

    #expect(result.count > 0)
}

@Test func asyncThrows() async {
    let service = MyAsyncService()

    // Test that async operation throws
    await #expect(throws: NetworkError.self) {
        try await service.fetchInvalidData()
    }
}
```

---

### Step 5: Test Error Handling

```swift
struct ErrorHandlingTests {

    @Test func invalidInputThrows() {
        #expect(throws: ValidationError.invalidInput) {
            try validateInput("")
        }
    }

    @Test func networkErrorRecovery() async throws {
        let service = NetworkService(mockFailOnFirst: true)

        // First call fails
        await #expect(throws: NetworkError.self) {
            try await service.fetch()
        }

        // Second call succeeds (after recovery)
        let result = try await service.fetch()
        #expect(result != nil)
    }
}
```

---

### Step 6: Test Network Server Endpoints

**File:** `iOS Health Sync AppTests/NetworkServerTests.swift`

```swift
import Testing
@testable import iOS_Health_Sync_App

struct NetworkServerTests {

    @Test func statusEndpointReturns200() async throws {
        let server = NetworkServer(
            healthKitService: MockHealthKitService(),
            auditService: MockAuditService()
        )

        let request = HTTPRequest(method: .GET, path: "/api/v1/status")
        let response = await server.handleRequest(request)

        #expect(response.status == .ok)
    }

    @Test func invalidEndpointReturns404() async throws {
        let server = NetworkServer(
            healthKitService: MockHealthKitService(),
            auditService: MockAuditService()
        )

        let request = HTTPRequest(method: .GET, path: "/invalid/path")
        let response = await server.handleRequest(request)

        #expect(response.status == .notFound)
    }

    @Test func samplesEndpointRequiresAuth() async throws {
        let server = NetworkServer(
            healthKitService: MockHealthKitService(),
            auditService: MockAuditService()
        )

        let request = HTTPRequest(
            method: .GET,
            path: "/api/v1/samples",
            headers: [:] // No auth header
        )
        let response = await server.handleRequest(request)

        #expect(response.status == .unauthorized)
    }
}
```

---

### Step 7: Test with Parameters

```swift
@Test(arguments: [
    (input: "steps", expected: HealthDataType.steps),
    (input: "heartRate", expected: HealthDataType.heartRate),
    (input: "invalid", expected: nil)
])
func parseHealthDataType(input: String, expected: HealthDataType?) {
    let result = HealthDataType(rawValue: input)
    #expect(result == expected)
}

@Test(arguments: 1...5)
func multipleIterations(count: Int) async throws {
    let service = HealthKitService(healthStore: MockHealthStore())
    let samples = try await service.fetchSamples(type: .steps, limit: count)
    #expect(samples.count <= count)
}
```

---

### Step 8: Run Tests

**In Xcode:**
- Press **Cmd+U** to run all tests
- Or click the diamond icon next to test functions

**From command line (iOS):**

```bash
xcodebuild test \
  -project "iOS Health Sync App/iOS Health Sync App.xcodeproj" \
  -scheme "HealthSyncTests" \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**From command line (CLI):**

```bash
cd macOS/HealthSyncCLI
swift test
```

**Run specific test:**

```bash
xcodebuild test \
  -project "iOS Health Sync App/iOS Health Sync App.xcodeproj" \
  -scheme "HealthSyncTests" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:iOS_Health_Sync_AppTests/HealthKitServiceTests/fetchSamplesReturnsData
```

---

## Verification

**Check test coverage:**

```bash
# Generate coverage report
xcodebuild test \
  -project "iOS Health Sync App.xcodeproj" \
  -scheme "HealthSyncTests" \
  -enableCodeCoverage YES

# View coverage in Xcode: Product → Show Code Coverage
```

---

## Common Issues

### Issue: "Cannot import module"

**Cause:** Test target doesn't have access to app module.

**Solution:**
Add `@testable import iOS_Health_Sync_App` at top of test file.

### Issue: "Actor isolation error"

**Cause:** Accessing actor-isolated state from test.

**Solution:**
Use `await` for actor methods or test on the actor's executor.

### Issue: "Test timeout"

**Cause:** Async test takes too long.

**Solution:**
```swift
@Test(.timeLimit(.minutes(1)))
func longRunningTest() async throws {
    // ...
}
```

---

## Test Organization

### Naming Convention

```swift
// Format: test[MethodName][Scenario][Expected]
@Test func fetchSamplesWithValidDateReturnsData() { }
@Test func fetchSamplesWithEmptyRangeReturnsEmpty() { }
@Test func fetchSamplesWithInvalidTypeThrows() { }
```

### Test Suites

```swift
struct HealthKitServiceTests {
    // Group related tests

    struct AuthorizationTests {
        @Test func requestAuthorizationSuccess() { }
        @Test func requestAuthorizationDenied() { }
    }

    struct FetchTests {
        @Test func fetchSteps() { }
        @Test func fetchHeartRate() { }
    }
}
```

---

## Mocking Best Practices

1. **Use protocols** - Define `HealthStoreProtocol` for mocking
2. **Inject dependencies** - Pass mocks via init
3. **Keep mocks simple** - Only mock what's needed
4. **Reset state** - Clear mock state between tests
5. **Verify interactions** - Check mock was called correctly

---

## See Also

- [Architecture](../reference/architecture.md) - System design
- [Swift Testing](https://developer.apple.com/documentation/testing) - Apple docs
- [Add Endpoint](./add-endpoint.md) - Adding new API endpoints

---

**Last Updated:** 2026-01-07
