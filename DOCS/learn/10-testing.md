# Chapter 10: Testing Your Code

**Building Reliable Software with Tests**

---

## Learning Objectives

After this chapter, you will be able to:

- ✅ Understand Swift Testing framework
- ✅ Write unit tests
- ✅ Create protocol-based mocks
- ✅ Test async code
- ✅ Handle test doubles

---

## The Simple Explanation

### Why Test?

**Tests** are code that verifies your code works correctly.

```
Without Tests:                    With Tests:
Write code                         Write code
  ↓                                 ↓
Run manually                       Run tests
  ↓                                 ↓
Find bug later                     Find bug immediately
  ↓                                 ↓
Fix in production                  Fix before release
```

**Benefits:**
- Catch bugs early
- Refactor safely
- Document behavior
- Design better APIs

### Types of Tests

```
Pyramid of Testing:

                    E2E Tests
                   (slow, few)
                   /          \
                  /            \
                 /              \
            Integration Tests
               (medium)
              /            \
             /              \
            /                \
        Unit Tests
      (fast, many)
```

| Test Type | Scope | Speed | Count |
|-----------|-------|-------|-------|
| **Unit** | Single function | Fast | Many |
| **Integration** | Multiple components | Medium | Some |
| **E2E** | Full app flow | Slow | Few |

---

## Swift Testing Framework

### What Is Swift Testing?

**Swift Testing** = Apple's modern testing framework (replaces XCTest).

```swift
// Old (XCTest)
import XCTest
class MyTests: XCTestCase {
    func testSomething() {
        XCTAssertEqual(2 + 2, 4)
    }
}

// New (Swift Testing)
import Testing
@Test func addNumbers() {
    #expect(2 + 2 == 4)
}
```

### Basic Test

```swift
import Testing

@Test("Addition works correctly") {
    let result = 2 + 2
    #expect(result == 4)
}
```

**Key features:**
- No class required
- `@Test` macro marks tests
- `#expect` for assertions
- Descriptive test names

---

## In Our Code: Test Structure

**File:** `iOS Health Sync AppTests/HealthKitServiceTests.swift`

```swift
import Testing
import Foundation
import HealthKit
@testable import iOS_Health_Sync_App

struct HealthKitServiceTests {
    // Tests go here
}
```

---

## Protocol-Based Mocking

### What Is Mocking?

**Mocking** = Creating fake implementations for testing.

```
Production:                      Testing:
Real HealthKit                  Mock HealthStore
    ↓                                 ↓
Can't control                   Control everything
Slow                            Fast
Requires device                 No device needed
```

### HealthStoreProtocol

**File:** `Services/HealthKit/HealthStoreProtocol.swift`

```swift
protocol HealthStoreProtocol {
    func requestAuthorization(
        toShare: Set<HKSampleType>?,
        read: Set<HKObjectType>?,
        completion: @escaping (Bool, Error?) -> Void
    )

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus

    func getRequestStatusForAuthorization(
        toShare: Set<HKSampleType>?,
        read: Set<HKObjectType>?,
        completion: @escaping (HKAuthorizationRequestStatus, Error?) -> Void
    )

    func execute(_ query: HKQuery)
}
```

### Mock Implementation

**File:** `iOS Health Sync AppTests/Mocks/MockHealthStore.swift`

```swift
actor MockHealthStore: HealthStoreProtocol {
    var authorizationResult: Result<Bool, Error> = .success(true)
    var authorizationStatus: HKAuthorizationStatus = .notDetermined
    var requestStatus: HKAuthorizationRequestStatus = .shouldRequest
    var executedQueries: [HKQuery] = []

    func requestAuthorization(
        toShare: Set<HKSampleType>?,
        read: Set<HKObjectType>?,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        switch authorizationResult {
        case .success(let success):
            completion(success, nil)
        case .failure(let error):
            completion(false, error)
        }
    }

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        authorizationStatus
    }

    func getRequestStatusForAuthorization(
        toShare: Set<HKSampleType>?,
        read: Set<HKObjectType>?,
        completion: @escaping (HKAuthorizationRequestStatus, Error?) -> Void
    ) {
        completion(requestStatus, nil)
    }

    func execute(_ query: HKQuery) {
        executedQueries.append(query)
    }
}
```

---

## Unit Tests

### Testing HealthKitService

```swift
@Test("HealthKitService returns ok when authorization succeeds")
func authorizationSuccess() async throws {
    // Arrange
    let mockStore = MockHealthStore()
    mockStore.authorizationResult = .success(true)
    let service = HealthKitService(store: mockStore)

    // Act
    let result = try await service.requestAuthorization(for: [.steps])

    // Assert
    #expect(result == true)
}
```

**The AAA Pattern:**
```
Arrange - Set up test data
  Act    - Call the code being tested
  Assert - Verify expected outcome
```

### Testing Async Code

```swift
@Test("HealthKitService fetches samples correctly")
func fetchSamples() async throws {
    // Arrange
    let mockStore = MockHealthStore()
    let service = HealthKitService(store: mockStore)
    let startDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
    let endDate = Date()

    // Act
    let response = await service.fetchSamples(
        types: [.steps],
        startDate: startDate,
        endDate: endDate,
        limit: 100,
        offset: 0
    )

    // Assert
    #expect(response.status == .ok)
    #expect(response.samples.isEmpty == true)  // Mock returns empty
}
```

### Testing Error Cases

```swift
@Test("HealthKitService handles authorization failure")
func authorizationFailure() async throws {
    // Arrange
    let mockStore = MockHealthStore()
    mockStore.authorizationResult = .failure(HealthError.authDenied)
    let service = HealthKitService(store: mockStore)

    // Act & Assert
    await #expect(throws: HealthError.self) {
        try await service.requestAuthorization(for: [.steps])
    }
}
```

---

## Parameterized Tests

### Testing Multiple Inputs

```swift
@Test("HealthDataType has correct sample types for all cases")
func healthDataTypeSampleTypes() {
    for dataType in HealthDataType.allCases {
        let sampleType = dataType.sampleType
        #expect(sampleType != nil, "\(dataType) should have a sample type")
    }
}
```

### Test with Arguments

```swift
@Test("Pagination works correctly", arguments: [
    (limit: 10, offset: 0, expectedCount: 10),
    (limit: 10, offset: 5, expectedCount: 5),
    (limit: 100, offset: 0, expectedCount: 50),
])
func pagination(limit: Int, offset: Int, expectedCount: Int) async throws {
    // Arrange
    let mockStore = MockHealthStore()
    mockStore.samples = createMockSamples(count: 50)
    let service = HealthKitService(store: mockStore)

    // Act
    let response = await service.fetchSamples(
        types: [.steps],
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset
    )

    // Assert
    #expect(response.returnedCount == expectedCount)
}
```

---

## NetworkServer Tests

### Mocking Dependencies

```swift
@Test("NetworkServer handles status request correctly")
func statusRequest() async throws {
    // Arrange
    let mockHealthService = MockHealthService()
    let mockPairingService = MockPairingService()
    let mockAuditService = MockAuditService()
    let modelContainer = try ModelContainer(
        for: SyncConfiguration.self,
        configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    )

    let server = NetworkServer(
        healthService: mockHealthService,
        pairingService: mockPairingService,
        auditService: mockAuditService,
        modelContainer: modelContainer,
        protectedDataAvailable: { true },
        deviceNameProvider: { "TestDevice" }
    )

    let request = HTTPRequest(
        method: "GET",
        path: "/api/v1/status",
        headers: ["Authorization": "Bearer test-token"],
        body: Data()
    )

    // Act
    let response = await server.route(request)

    // Assert
    #expect(response.statusCode == 200)
}
```

### Testing Rate Limiting

```swift
@Test("Rate limiting blocks excessive requests")
func rateLimiting() async throws {
    // Arrange
    let mockPairingService = MockPairingService()
    mockPairingService.validateTokenResult = true

    let server = NetworkServer(...)
    let request = HTTPRequest(
        method: "GET",
        path: "/api/v1/status",
        headers: ["Authorization": "Bearer test-token"],
        body: Data()
    )

    // Act - Send 61 requests (rate limit is 60)
    var responses: [HTTPResponse] = []
    for _ in 0..<61 {
        responses.append(await server.route(request))
    }

    // Assert
    let blockedCount = responses.filter { $0.statusCode == 429 }.count
    #expect(blockedCount > 0, "Should block some requests")
}
```

---

## Test Doubles

### Types of Test Doubles

| Double | Purpose | Example |
|--------|---------|---------|
| **Dummy** | Fill parameter | `DummyLogger()` |
| **Stub** | Return canned values | `MockStore(returning: 42)` |
| **Spy** | Record calls | `SpyService()` |
| **Fake** | Working implementation | `InMemoryDatabase()` |
| **Mock** | Verify behavior | `MockHealthStore()` |

### Spy Example

```swift
actor SpyAuditService: AuditServiceProtocol {
    var recordedEvents: [(String, [String: String])] = []

    func record(eventType: String, details: [String: String]) async {
        recordedEvents.append((eventType, details))
    }
}

@Test("Server logs audit events")
func auditLogging() async throws {
    // Arrange
    let spyAudit = SpyAuditService()
    let server = NetworkServer(..., auditService: spyAudit)

    // Act
    await server.route(someRequest)

    // Assert
    #expect(spyAudit.recordedEvents.count == 1)
    #expect(spyAudit.recordedEvents.first?.0 == "api.request")
}
```

---

## Testing Best Practices

### 1. Test Isolation

```swift
// ❌ WRONG: Tests depend on each other
var sharedState: Service?

@Test func test1() {
    sharedState = Service()
}

@Test func test2() {
    sharedState.doSomething()  // Depends on test1!
}

// ✅ RIGHT: Each test is independent
@Test func test1() {
    let service = Service()
    // Test...
}

@Test func test2() {
    let service = Service()
    // Test...
}
```

### 2. Descriptive Test Names

```swift
// ❌ WRONG: Vague name
@Test func test1() { }

// ✅ RIGHT: Descriptive name
@Test("HealthKitService returns error when HealthKit unavailable") {
}
```

### 3. One Assertion Per Test

```swift
// ❌ WRONG: Multiple things tested
@Test("Everything works") {
    #expect(service.isAvailable() == true)
    #expect(service.canAuthorize() == true)
    #expect(service.dataCount == 42)
}

// ✅ RIGHT: Separate tests
@Test("HealthKit is available on supported devices") {
    #expect(service.isAvailable() == true)
}

@Test("Service can request authorization") {
    #expect(service.canAuthorize() == true)
}

@Test("Initial data count is zero") {
    #expect(service.dataCount == 0)
}
```

### 4. Arrange-Act-Assert

```swift
@Test("Pagination returns correct page") async throws {
    // Arrange
    let service = HealthKitService(store: mockStore)
    let startDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
    let endDate = Date()
    mockStore.samples = Array(0..<150).map { _ in mockSample }

    // Act
    let response = await service.fetchSamples(
        types: [.steps],
        startDate: startDate,
        endDate: endDate,
        limit: 50,
        offset: 100
    )

    // Assert
    #expect(response.returnedCount == 50)
    #expect(response.hasMore == true)
}
```

---

## Running Tests

### Command Line

```bash
# Run all tests
swift test

# Run specific test
swift test --filter HealthKitServiceTests

# Run with verbose output
swift test --verbose

# Run with code coverage
swift test --enable-code-coverage
```

### Xcode

```
⌘U - Run all tests
⌘⇧U - Run tests with cursor
⌘⌃U - Repeat last test
```

---

## Test Coverage

### What Is Coverage?

**Coverage** = Percentage of code executed by tests.

```
100% Coverage                    50% Coverage
┌─────────────────┐            ┌─────────────────┐
│ func add(a, b)  │            │ func add(a, b)  │
│   return a + b  │            │   if a > 0 {    │  ← Tested
│ }               │            │     return a + b│
└─────────────────┘            │   }             │  ← Not tested
     All tested                 │   return a      │
                                 }               │
                                  └─────────────────┘
                                       Some untested
```

### Generating Coverage

```bash
# Generate coverage report
swift test --enable-code-coverage

# Convert to report
xcrun llvm-cov report \
  .build/debug/HealthSyncCLIPackageTests.xctest/Contents/MacOS/HealthSyncCLIPackageTests \
  -instr-profile=.build/debug/codecov/default.profdata \
  > coverage.txt
```

---

## Exercises

### 🟢 Beginner: Write Your First Test

**Task:** Test this function:

```swift
func add(_ a: Int, _ b: Int) -> Int {
    return a + b
}

@Test("Addition works") {
    // Your test here
}
```

---

### 🟡 Intermediate: Test with Mock

**Task:** Test this service with a mock:

```swift
protocol DataService {
    func fetch() async throws -> [Item]
}

actor ItemProcessor {
    let service: DataService

    func processCount() async throws -> Int {
        let items = try await service.fetch()
        return items.count
    }
}

// Write a test using MockDataService
```

---

### 🔴 Advanced: Test Async Error Handling

**Task:** Test all error paths:

```swift
func fetchWithRetry(
    service: DataService,
    maxRetries: Int = 3
) async throws -> Data {
    var lastError: Error?
    for _ in 0..<maxRetries {
        do {
            return try await service.fetch()
        } catch {
            lastError = error
        }
    }
    throw lastError!
}

// Test:
// 1. Success on first try
// 2. Success on retry
// 3. Failure after all retries
// 4. Different error types
```

---

## Common Pitfalls

### Pitfall 1: Testing Implementation

```swift
// ❌ WRONG: Tests implementation details
@Test("Service calls store.execute") {
    service.fetch()
    #expect(mockStore.executeCallCount == 1)  // Fragile!
}

// ✅ RIGHT: Tests behavior
@Test("Service returns data from store") {
    let result = await service.fetch()
    #expect(result.count == 42)  // Meaningful!
}
```

### Pitfall 2: Brittle Mocks

```swift
// ❌ WRONG: Exact match required
when(mock.fetch()).thenReturn(data)
// Fails if we add a parameter!

// ✅ RIGHT: Flexible matching
when(mock.fetch(any())).thenReturn(data)
```

### Pitfall 3: Testing Third Parties

```swift
// ❌ WRONG: Testing HealthKit itself
@Test("HKHealthStore authorization works") {
    // Don't test Apple's code!
}

// ✅ RIGHT: Test our code
@Test("HealthKitService handles authorization correctly") {
    // Test our logic with mock
}
```

---

## Key Takeaways

### ✅ Testing Patterns

| Pattern | Purpose |
|---------|---------|
| **Protocol mocking** | Test without dependencies |
| **AAA** | Arrange-Act-Assert structure |
| **Test isolation** | Independent tests |
| **Descriptive names** | Self-documenting |
| **Coverage** | Measure test completeness |

---

## Further Reading

### Swift Testing
- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [Introduction to Swift Testing](https://www.swift.org/documentation/testing)

### Testing Practices
- [Test-Driven Development by Example](https://www.oreilly.com/library/view/test-driven-development/0321146530/)
- [Working Effectively with Legacy Code](https://www.oreilly.com/library/view/working-effectively-with/0131177052/)

---

## Congratulations!

You've completed the **iOS Health Sync Learning Guide**! 🎉

### What You've Mastered

| Chapter | Skills |
|---------|--------|
| 1 | Understanding the app and its purpose |
| 2 | Layered architecture and clean code |
| 3 | Swift 6 concurrency patterns |
| 4 | SwiftUI declarative UI |
| 5 | SwiftData persistence |
| 6 | HealthKit integration |
| 7 | Security best practices |
| 8 | Network programming |
| 9 | CLI development |
| 10 | Testing strategies |

### Next Steps

1. **Contribute to the project** - Fix bugs, add features
2. **Build your own app** - Apply what you've learned
3. **Teach others** - Explain concepts to reinforce learning
4. **Explore deeper** - Read source code, experiment

### Remember

> "The best way to learn is to teach."
> — Richard Feynman

**Now go forth and build amazing things!** 🚀

---

**End of Guide**
