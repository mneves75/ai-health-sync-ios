# Add API Endpoint: Extend the Network Server

**Add a new HTTP endpoint to the iOS app's embedded server**

---

**Time:** 45 minutes
**Difficulty:** Intermediate
**Prerequisites:**
- [ ] Xcode 26 with project open
- [ ] Understanding of REST API design
- [ ] Familiarity with Swift async/await

---

## Goal

Add a new API endpoint to the iOS app's network server (e.g., `/api/v1/aggregate` for aggregated data).

---

## Steps

### Step 1: Define the Endpoint

Plan your endpoint:

| Property | Value |
|----------|-------|
| **Path** | `/api/v1/aggregate` |
| **Method** | GET |
| **Query Params** | `types`, `start`, `end`, `period` |
| **Response** | JSON aggregated data |

---

### Step 2: Add Route Handler

**File:** `iOS Health Sync App/Services/Network/NetworkServer.swift`

Add a new case to the route handler:

```swift
private func handleRequest(_ request: HTTPRequest) async -> HTTPResponse {
    switch (request.method, request.path) {
    // Existing routes
    case (.GET, "/api/v1/status"):
        return await handleStatus(request)
    case (.GET, "/api/v1/health"):
        return await handleHealth(request)
    case (.GET, "/api/v1/samples"):
        return await handleSamples(request)

    // Add new route
    case (.GET, "/api/v1/aggregate"):
        return await handleAggregate(request)

    default:
        return HTTPResponse(status: .notFound, body: ["error": "Not found"])
    }
}
```

---

### Step 3: Implement the Handler

Add the handler function:

```swift
private func handleAggregate(_ request: HTTPRequest) async -> HTTPResponse {
    // 1. Parse query parameters
    guard let typesParam = request.queryParams["types"],
          let startParam = request.queryParams["start"],
          let endParam = request.queryParams["end"] else {
        return HTTPResponse(
            status: .badRequest,
            body: ["error": "Missing required parameters: types, start, end"]
        )
    }

    // 2. Parse dates
    let dateFormatter = ISO8601DateFormatter()
    guard let startDate = dateFormatter.date(from: startParam),
          let endDate = dateFormatter.date(from: endParam) else {
        return HTTPResponse(
            status: .badRequest,
            body: ["error": "Invalid date format. Use ISO 8601."]
        )
    }

    // 3. Parse types
    let typeStrings = typesParam.split(separator: ",").map(String.init)
    let types = typeStrings.compactMap { HealthDataType(rawValue: $0) }

    guard !types.isEmpty else {
        return HTTPResponse(
            status: .badRequest,
            body: ["error": "No valid types specified"]
        )
    }

    // 4. Parse aggregation period
    let period = request.queryParams["period"] ?? "daily"

    // 5. Fetch and aggregate data
    do {
        let aggregates = try await healthKitService.fetchAggregates(
            types: types,
            startDate: startDate,
            endDate: endDate,
            period: AggregationPeriod(rawValue: period) ?? .daily
        )

        // 6. Audit the access
        await auditService.log(
            action: .dataFetch,
            details: ["endpoint": "aggregate", "types": typeStrings]
        )

        // 7. Return response
        return HTTPResponse(status: .ok, body: [
            "aggregates": aggregates.map { $0.toDTO() },
            "query": [
                "types": typeStrings,
                "start": startParam,
                "end": endParam,
                "period": period
            ]
        ])
    } catch {
        return HTTPResponse(
            status: .internalServerError,
            body: ["error": error.localizedDescription]
        )
    }
}
```

---

### Step 4: Add Supporting Types

**File:** `iOS Health Sync App/Core/DTO/AggregateDTO.swift` (new file)

```swift
import Foundation

enum AggregationPeriod: String, Codable {
    case hourly
    case daily
    case weekly
    case monthly
}

struct AggregateDTO: Codable, Sendable {
    let period: String
    let type: String
    let total: Double
    let average: Double
    let min: Double
    let max: Double
    let count: Int
}

extension HealthKitService {
    func fetchAggregates(
        types: [HealthDataType],
        startDate: Date,
        endDate: Date,
        period: AggregationPeriod
    ) async throws -> [AggregateDTO] {
        var results: [AggregateDTO] = []

        for type in types {
            let samples = try await fetchSamples(
                type: type,
                startDate: startDate,
                endDate: endDate
            )

            let grouped = groupByPeriod(samples, period: period)

            for (periodKey, periodSamples) in grouped {
                let values = periodSamples.map { $0.value }
                results.append(AggregateDTO(
                    period: periodKey,
                    type: type.rawValue,
                    total: values.reduce(0, +),
                    average: values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count),
                    min: values.min() ?? 0,
                    max: values.max() ?? 0,
                    count: values.count
                ))
            }
        }

        return results
    }
}
```

---

### Step 5: Update HTTPTypes

**File:** `iOS Health Sync App/Services/Network/HTTPTypes.swift`

Ensure your response types are supported:

```swift
struct HTTPResponse: Sendable {
    let status: HTTPStatus
    let headers: [String: String]
    let body: Data

    init(status: HTTPStatus, body: [String: Any]) {
        self.status = status
        self.headers = ["Content-Type": "application/json"]
        self.body = try! JSONSerialization.data(withJSONObject: body)
    }

    init(status: HTTPStatus, body: Encodable) {
        self.status = status
        self.headers = ["Content-Type": "application/json"]
        self.body = try! JSONEncoder().encode(body)
    }
}
```

---

### Step 6: Add Tests

**File:** `iOS Health Sync AppTests/NetworkServerTests.swift`

```swift
@Test func testAggregateEndpoint() async throws {
    // Arrange
    let server = NetworkServer(healthKitService: mockHealthKitService)
    let request = HTTPRequest(
        method: .GET,
        path: "/api/v1/aggregate",
        queryParams: [
            "types": "steps",
            "start": "2026-01-01T00:00:00Z",
            "end": "2026-01-07T23:59:59Z",
            "period": "daily"
        ]
    )

    // Act
    let response = await server.handleRequest(request)

    // Assert
    #expect(response.status == .ok)
    let body = try JSONDecoder().decode(AggregateResponse.self, from: response.body)
    #expect(!body.aggregates.isEmpty)
}

@Test func testAggregateEndpointMissingParams() async throws {
    let server = NetworkServer(healthKitService: mockHealthKitService)
    let request = HTTPRequest(
        method: .GET,
        path: "/api/v1/aggregate",
        queryParams: [:] // Missing params
    )

    let response = await server.handleRequest(request)

    #expect(response.status == .badRequest)
}
```

---

### Step 7: Update CLI (Optional)

**File:** `macOS/HealthSyncCLI/Sources/Commands/AggregateCommand.swift` (new file)

```swift
import ArgumentParser

struct AggregateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "aggregate",
        abstract: "Fetch aggregated health data"
    )

    @Option(help: "Data types to aggregate")
    var types: String

    @Option(help: "Start date (ISO 8601)")
    var start: String

    @Option(help: "End date (ISO 8601)")
    var end: String

    @Option(help: "Aggregation period: hourly, daily, weekly, monthly")
    var period: String = "daily"

    func run() async throws {
        let client = HealthSyncClient.shared
        let response = try await client.get(
            path: "/api/v1/aggregate",
            params: [
                "types": types,
                "start": start,
                "end": end,
                "period": period
            ]
        )
        print(response)
    }
}
```

---

## Verification

**Build and run:**

```bash
# Build iOS app
xcodebuild build -project "iOS Health Sync App.xcodeproj" -scheme "iOS Health Sync App"

# Start server in app

# Test endpoint via curl
curl "http://localhost:8080/api/v1/aggregate?types=steps&start=2026-01-01T00:00:00Z&end=2026-01-07T23:59:59Z&period=daily"
```

**Expected response:**

```json
{
  "aggregates": [
    {
      "period": "2026-01-01",
      "type": "steps",
      "total": 10234,
      "average": 1023.4,
      "min": 45,
      "max": 2345,
      "count": 10
    }
  ],
  "query": {
    "types": ["steps"],
    "start": "2026-01-01T00:00:00Z",
    "end": "2026-01-07T23:59:59Z",
    "period": "daily"
  }
}
```

---

## Common Issues

### Issue: "Route not found"

**Cause:** Route not added to switch statement.

**Solution:**
Verify the route case is added to `handleRequest` function.

### Issue: "Method not allowed"

**Cause:** Using wrong HTTP method.

**Solution:**
Ensure the method matches (GET, POST, etc.).

### Issue: "JSON encoding failed"

**Cause:** Response type not Codable.

**Solution:**
Ensure all response types conform to `Codable` and `Sendable`.

---

## Best Practices

1. **Validate all input** - Check required params, parse dates
2. **Return meaningful errors** - Include error details in response
3. **Audit access** - Log all data access via AuditService
4. **Use proper status codes** - 200, 400, 401, 404, 500
5. **Document the endpoint** - Update API reference docs
6. **Write tests** - Test happy path and error cases

---

## See Also

- [Architecture](../reference/architecture.md) - System design
- [Network Server API](../reference/api/network-server.md) - Existing endpoints
- [Write Tests](./write-tests.md) - Testing guide

---

**Last Updated:** 2026-01-07
