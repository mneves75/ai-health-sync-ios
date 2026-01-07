# Chapter 8: Networking - Device Communication

**Building HTTP Servers and Clients**

---

## Learning Objectives

After this chapter, you will be able to:

- ✅ Understand HTTP server architecture
- ✅ Build a TLS server
- ✅ Handle requests and responses
- ✅ Implement Bonjour discovery
- ✅ Build HTTP clients

---

## The Simple Explanation

### What Is Networking?

**Networking** lets devices talk to each other:

```
Without Networking:              With Networking:
┌─────────┐                    ┌─────────┐
│ Device  │                    │ Device  │───┐
│   A     │  Can't talk        │   A     │   │
└─────────┘  to Device B       └─────────┘   │
                                           │
┌─────────┐                               │
│ Device  │                    ┌─────────┐   │
│   B     │  Can't talk        │   B     │◄──┘
└─────────┘  to Device A       └─────────┘
```

**HTTP** = The language devices speak
**Server** = The device that serves data
**Client** = The device that requests data

### Our Network Architecture

```
┌─────────────────────────────────────────┐
│  iOS App (SERVER)                       │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  NetworkServer (actor)           │  │
│  │  - Listens on port               │  │
│  │  - Accepts TLS connections       │  │
│  │  - Routes HTTP requests          │  │
│  │  - Validates tokens              │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
                    ↑
                    │ TLS 1.3
                    │ mTLS
                    │
┌─────────────────────────────────────────┐
│  macOS CLI (CLIENT)                     │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  URLSession client               │  │
│  │  - Discovers server (Bonjour)    │  │
│  │  - Validates certificate         │  │
│  │  - Sends HTTP requests           │  │
│  │  - Processes responses           │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

---

## The Server: NetworkServer

**File:** `Services/Network/NetworkServer.swift:11-50`

### Actor for Thread Safety

```swift
actor NetworkServer {
    private let healthService: HealthDataProviding
    private let pairingService: PairingService
    private let auditService: AuditService
    private let modelContainer: ModelContainer

    private var listener: NWListener?
    private(set) var port: Int = 0
    private(set) var certificateFingerprint: String = ""
    private var requestLog: [String: [Date]] = [:]

    // Configuration
    private let rateLimit = 60              // requests per minute
    private let rateWindow: TimeInterval = 60
    private let maxHeadersBytes = 16_384    // 16 KB
    private let maxBodyBytes = 1_048_576    // 1 MB
    private let maxRequestDuration: TimeInterval = 10
}
```

**Why actor?**
- Server state is mutable
- Multiple connections can happen
- Actor prevents races
- Thread-safe logging

### Starting the Server

```swift
// File: Services/Network/NetworkServer.swift:52-83
func start() async throws {
    if listener != nil { return }  // Already running

    // Load TLS identity
    let identity = try identityProvider()
    certificateFingerprint = identity.fingerprint

    // Configure TLS
    let tlsOptions = NWProtocolTLS.Options()
    sec_protocol_options_set_min_tls_protocol_version(
        tlsOptions.securityProtocolOptions,
        .TLSv13
    )

    if let secIdentity = sec_identity_create(identity.identity) {
        sec_protocol_options_set_local_identity(
            tlsOptions.securityProtocolOptions,
            secIdentity
        )
    }

    // Create listener
    let parameters = NWParameters(tls: tlsOptions)
    parameters.allowLocalEndpointReuse = true
    let listener = try NWListener(using: parameters, on: listenerPortOverride ?? .any)

    // Bonjour service
    let deviceName = await deviceNameProvider()
    listener.service = NWListener.Service(
        name: deviceName,
        type: "_healthsync._tcp"
    )

    // Connection handler
    listener.newConnectionHandler = { [weak self] connection in
        guard let self else { return }
        Task { await self.handleConnection(connection) }
    }

    // Start listening
    listener.start(queue: .global())
    try await awaitReady(listener)

    self.listener = listener
    self.port = Int(listener.port?.rawValue ?? 0)
}
```

**What's happening:**
1. Load or create TLS certificate
2. Configure TLS 1.3
3. Create NWListener with TLS
4. Advertise via Bonjour
5. Set up connection handler
6. Start listening
7. Wait for ready state
8. Store port number

### Handling Connections

```swift
// File: Services/Network/NetworkServer.swift:95-123
private func handleConnection(_ connection: NWConnection) async {
    connection.stateUpdateHandler = { state in
        if case .failed(let error) = state {
            AppLoggers.network.error("Connection failed")
        }
    }

    connection.start(queue: .global())
    defer { connection.cancel() }

    do {
        let request = try await receiveRequest(on: connection)
        let response = await route(request)
        await send(response: response, on: connection)
    } catch let error as HTTPParseError {
        let response: HTTPResponse
        switch error {
        case .bodyTooLarge:
            response = HTTPResponse.plain(statusCode: 413, reason: "Payload Too Large",
                                        message: "Request body too large")
        case .incomplete:
            response = HTTPResponse.plain(statusCode: 408, reason: "Request Timeout",
                                        message: "Request incomplete")
        case .invalidRequest:
            response = HTTPResponse.plain(statusCode: 400, reason: "Bad Request",
                                        message: "Invalid request")
        }
        await send(response: response, on: connection)
    } catch {
        await send(response: HTTPResponse.plain(statusCode: 400), on: connection)
    }
}
```

**Connection lifecycle:**
```
1. Connection arrives
       ↓
2. Start connection
       ↓
3. Receive request (with timeout)
       ↓
4. Route to handler
       ↓
5. Get response
       ↓
6. Send response
       ↓
7. Close connection
```

### Receiving Requests

```swift
// File: Services/Network/NetworkServer.swift:349-368
private func receiveRequest(on connection: NWConnection) async throws -> HTTPRequest {
    var buffer = Data()
    let start = Date()

    while true {
        // Timeout check
        if Date().timeIntervalSince(start) > maxRequestDuration {
            throw HTTPParseError.incomplete
        }

        // Receive chunk
        let chunk = try await receiveData(on: connection)
        if chunk.isEmpty {
            throw HTTPParseError.incomplete
        }

        buffer.append(chunk)

        // Size limits
        if buffer.count > maxHeadersBytes + maxBodyBytes {
            throw HTTPParseError.bodyTooLarge
        }

        // Try to parse
        if let request = try parseRequest(from: buffer) {
            return request
        }
    }
}
```

**Incremental parsing:**
```
Chunk 1 arrives: "GET /api/v1/stat"
    ↓ Not complete yet

Chunk 2 arrives: "us HTTP/1.1\r\nHost: l"
    ↓ Not complete yet

Chunk 3 arrives: "ocalhost\r\n\r\n"
    ↓ Complete! Parse and return
```

---

## HTTP Protocol

### HTTP Request Format

```
GET /api/v1/status HTTP/1.1\r\n
Host: localhost\r\n
Authorization: Bearer abc123\r\n
Content-Type: application/json\r\n
\r\n
{ "key": "value" }  // Body
```

### HTTP Response Format

```
HTTP/1.1 200 OK\r\n
Content-Type: application/json\r\n
Content-Length: 42\r\n
\r\n
{ "status": "ok" }  // Body
```

### In Our Code: HTTP Types

**File:** `Services/Network/HTTPTypes.swift`

```swift
struct HTTPRequest {
    let method: String      // GET, POST, etc.
    let path: String        // /api/v1/status
    let headers: [String: String]
    let body: Data
}

struct HTTPResponse {
    let statusCode: Int
    let reasonPhrase: String
    let headers: [String: String]
    let body: Data

    func toData() -> Data {
        var response = "HTTP/1.1 \(statusCode) \(reasonPhrase)\r\n"
        for (key, value) in headers {
            response += "\(key): \(value)\r\n"
        }
        response += "\r\n"
        return response.data(using: .utf8)! + body
    }
}
```

---

## Request Routing

**File:** `Services/Network/NetworkServer.swift:125-159`

```swift
func route(_ request: HTTPRequest) async -> HTTPResponse {
    let path = request.path
    let method = request.method
    let requestId = UUID().uuidString

    // Public endpoint: pairing
    if path == "/api/v1/pair" && method == "POST" {
        return await handlePair(request, requestId: requestId)
    }

    // Authenticated endpoints
    guard let token = bearerToken(from: request.headers),
          await pairingService.validateToken(token) else {
        await auditService.record(eventType: "security.unauthorized_access",
                                 details: ["path": path])
        return HTTPResponse.plain(statusCode: 401, reason: "Unauthorized",
                                message: "Missing or invalid token")
    }

    // Rate limiting
    if isRateLimited(token: token) {
        await auditService.record(eventType: "security.rate_limit_exceeded")
        return HTTPResponse.plain(statusCode: 429, reason: "Too Many Requests")
    }

    // Route handlers
    switch (method, path) {
    case ("GET", "/api/v1/status"):
        return await handleStatus(requestId: requestId)
    case ("GET", "/api/v1/health/types"):
        return await handleTypes(requestId: requestId)
    case ("POST", "/api/v1/health/data"):
        return await handleHealthData(request, requestId: requestId)
    default:
        return HTTPResponse.plain(statusCode: 404, reason: "Not Found")
    }
}
```

**Routing logic:**
```
1. Check if public route (pairing)
       ↓
2. Validate authentication token
       ↓
3. Check rate limit
       ↓
4. Match route to handler
       ↓
5. Return handler's response
```

### API Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/v1/pair` | POST | No | Device pairing |
| `/api/v1/status` | GET | Yes | Server status |
| `/api/v1/health/types` | GET | Yes | Enabled types |
| `/api/v1/health/data` | POST | Yes | Fetch health data |

---

## Bonjour Discovery

### What Is Bonjour?

**Bonjour** (Zeroconf) = Network service discovery

```
Without Bonjour:                    With Bonjour:
User types:                         CLI discovers:
192.168.1.100:8443                  ┌──────────────┐
(How do I know the IP?)             │ Found server │
                                    │ 192.168.1.100│
                                    │ Port: 8443   │
                                    └──────────────┘
```

**Bonjour works like:**
```
Server: "I'm HealthSync server!"
Client: "Who's HealthSync server?"
Server: "Me! At 192.168.1.100:8443"
```

### Advertising the Service

```swift
// In NetworkServer.start()
listener.service = NWListener.Service(
    name: deviceName,
    type: "_healthsync._tcp"
)
```

**Service type format:**
- `_healthsync` = Our app identifier
- `._tcp` = TCP protocol

### Browsing for Services

**File:** `macOS/HealthSyncCLI/Sources/HealthSyncCLI/main.swift`

```swift
func discoverServers() async -> [DiscoveredServer] {
    await withCheckedContinuation { continuation in
        var servers: [DiscoveredServer] = []

        let browser = NWBrowser(
            for: .bonjour(type: "_healthsync._tcp", domain: nil),
            using: .tcp
        )

        browser.browseResultsChangedHandler = { results, changes in
            for result in results {
                if case .service(let name, let type, let domain) = result.endpoint,
                   case .bonjour(let txtRecords) = result.metadata {
                    servers.append(DiscoveredServer(
                        name: name,
                        host: result.metadata[.hostname] as? String ?? "",
                        port: result.metadata[.port] as? Int ?? 0,
                        txtRecords: txtRecords
                    ))
                }
            }
        }

        browser.start(queue: .main())

        // Continue after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            browser.cancel()
            continuation.resume(returning: servers)
        }
    }
}
```

---

## The Client: macOS CLI

### URLSession Configuration

```swift
// File: macOS/HealthSyncCLI/Sources/HealthSyncCLI/main.swift
func createSession(fingerprint: String) -> URLSession {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30

    // Certificate pinning delegate
    let delegate = CertificateDelegate(expectedFingerprint: fingerprint)

    return URLSession(
        configuration: config,
        delegate: delegate,
        delegateQueue: OperationQueue()
    )
}
```

### Making Requests

```swift
func fetchHealthData(
    host: String,
    port: Int,
    token: String,
    types: [String],
    format: OutputFormat
) async throws {
    let url = URL(string: "https://\(host):\(port)/api/v1/health/data")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let requestBody = HealthDataRequest(
        types: types,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: 0
    )

    request.httpBody = try JSONEncoder().encode(requestBody)

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw CLIError.requestFailed
    }

    let healthResponse = try JSONDecoder().decode(HealthDataResponse.self, from: data)

    // Process and output
    switch format {
    case .csv:
        outputCSV(healthResponse.samples)
    case .json:
        outputJSON(healthResponse.samples)
    }
}
```

---

## Error Handling

### Network Errors

```swift
enum NetworkError: Error {
    case connectionFailed
    case requestTimeout
    case invalidResponse
    case serverError(Int)
    case rateLimited
    case unauthorized
}
```

### Graceful Degradation

```swift
do {
    let data = try await fetchData()
} catch let error as NetworkError {
    switch error {
    case .connectionFailed:
        print("Cannot connect to server. Check network.")
    case .unauthorized:
        print("Pairing expired. Please re-pair.")
    case .rateLimited:
        print("Too many requests. Wait a moment.")
    default:
        print("Error: \(error.localizedDescription)")
    }
}
```

---

## Exercises

### 🟢 Beginner: Parse HTTP Request

**Task:** Parse this HTTP request:

```
GET /api/v1/test HTTP/1.1\r\n
Host: localhost\r\n
\r\n
```

```swift
func parseRequest(_ data: Data) -> HTTPRequest? {
    // Extract method, path, headers
}
```

---

### 🟡 Intermediate: Implement Route Handler

**Task:** Create a route handler for `/api/v1/version`:

```swift
func handleVersion(requestId: String) async -> HTTPResponse {
    // Return version info
    // Log to audit
}
```

---

### 🔴 Advanced: Implement Retry Logic

**Task:** Add exponential backoff retry:

```swift
func fetchWithRetry<T>(
    maxRetries: Int = 3,
    operation: () async throws -> T
) async throws -> T {
    // Implement:
    // - Try operation
    // - On failure, wait 2^retry seconds
    // - Retry up to maxRetries
    // - Throw if all retries fail
}
```

---

## Common Pitfalls

### Pitfall 1: Blocking on main thread

```swift
// WRONG: Blocks UI
let data = try Data(contentsOf: url)

// RIGHT: Async
let (data, _) = try await URLSession.shared.data(from: url)
```

### Pitfall 2: Not handling timeuts

```swift
// WRONG: Hangs forever
let (data, _) = try await session.data(for: request)

// RIGHT: Timeout
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30
```

### Pitfall 3: Ignoring certificate validation

```swift
// WRONG: Trusts everything
let config = URLSessionConfiguration.default
config.urlCredential = URLCredential(trust: everything)

// RIGHT: Validate certificate
let delegate = CertificateDelegate(expectedFingerprint: fp)
let session = URLSession(delegate: delegate)
```

---

## Key Takeaways

### ✅ Networking Patterns

| Pattern | Purpose |
|---------|---------|
| **Actor server** | Thread-safe state |
| **TLS 1.3** | Encrypt transport |
| **Bonjour** | Service discovery |
| **Token auth** | Bearer tokens |
| **Rate limiting** | Prevent abuse |
| **Async/await** | Non-blocking I/O |

---

## Coming Next

In **Chapter 9: macOS CLI Companion**, you'll learn:

- Command-line interface design
- Argument parsing
- Output formatting
- Error handling

---

**Next Chapter:** [macOS CLI Companion](09-cli.md) →
