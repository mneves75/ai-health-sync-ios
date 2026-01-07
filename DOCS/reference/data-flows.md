# Data Flow Diagrams

**Visual guides for understanding how data moves through the system**

---

## Overview

This document provides detailed data flow diagrams for the key operations in iOS Health Sync. Each diagram shows:

- 🔄 **Data flow** - How data moves between components
- 🔐 **Security boundaries** - Where authentication/encryption happens
- ⚠️ **Error paths** - How failures are handled
- 📊 **Data transformations** - How data changes format

---

## 1. Complete User Journey: First-Time Setup

This diagram shows the complete flow from a new user to their first successful health data fetch.

```mermaid
flowchart TD
    Start[User downloads app] --> Clone[Clone repository]
    Clone --> BuildiOS[Build iOS app in Xcode]
    Clone --> BuildCLI[Build CLI with swift build]

    BuildiOS --> RuniOS[Run iOS app]
    RuniOS --> Auth[HealthKit authorization prompt]
    Auth -->|User allows| AuthGranted[Authorization granted]
    Auth -->|User denies| AuthDenied[Show error message]

    AuthGranted --> StartServer[User taps Start Server]
    StartServer --> GenerateCert[Generate TLS certificate]
    GenerateCert --> StoreKeychain[Store in Keychain]
    StoreKeychain --> ServerRunning[Server running on port]

    BuildCLI --> Discover[User runs: healthsync discover]
    ServerRunning -->|Bonjour broadcast| Discover
    Discover --> DeviceFound[Device found]

    DeviceFound --> ShowQR[User taps: Show QR Code]
    ShowQR --> GenerateToken[Generate pairing token]
    GenerateToken --> DisplayQR[Display QR code]

    DisplayQR --> CopyQR[User copies QR code]
    CopyQR --> Scan[User runs: healthsync scan]
    Scan --> ParseQR[Parse QR code]
    ParseQR --> ConnectTLS[Connect via TLS 1.3]

    ConnectTLS -->|mTLS handshake| VerifyCert[Server verifies client cert]
    VerifyCert -->|Valid| PairSuccess[Pairing successful]
    VerifyCert -->|Invalid| PairFail[Pairing failed]

    PairSuccess --> Fetch[User runs: healthsync fetch]
    Fetch --> ValidateToken[Server validates Bearer token]
    ValidateToken -->|Valid| QueryHK[Query HealthKit]
    QueryHK --> MapDTO[Map to DTO]
    MapDTO --> ReturnJSON[Return JSON to CLI]
    ReturnJSON --> OutputCSV[CLI outputs CSV]

    style AuthGranted fill:#e1ffe1
    style PairSuccess fill:#e1ffe1
    style OutputCSV fill:#e1ffe1
    style AuthDenied fill:#ffe1e1
    style PairFail fill:#ffe1e1
```

**Key Points:**
- User must grant HealthKit authorization before any data access
- TLS certificate is generated automatically on first run
- QR code expires after 5 minutes for security
- mTLS handshake requires both certificates to be valid
- Every fetch request validates the Bearer token

---

## 2. HealthKit Data Fetch Flow

Detailed flow of a single health data fetch operation.

```mermaid
sequenceDiagram
    participant User
    participant CLI as healthsync CLI
    participant Server as NetworkServer
    participant Pairing as PairingService
    participant HK as HealthKitService
    participant Store as HealthKit Store

    User->>CLI: healthsync fetch --types steps
    CLI->>CLI: Validate arguments
    CLI->>CLI: Build HTTP request
    CLI->>Server: POST /api/v1/health/data<br/>+ Bearer token

    Server->>Pairing: validateToken(token)
    Pairing->>Pairing: hashToken(token)
    Pairing-->>Server: true/false

    alt Token invalid
        Server-->>CLI: 401 Unauthorized
        CLI-->>User: Error: Invalid token
    else Token valid
        Server->>Server: Check rate limits
        Server->>Server: Parse request body

        alt Invalid request
            Server-->>CLI: 400 Bad Request
        else Valid request
            Server->>HK: fetchSamples(types, dates, limit)
            HK->>Store: Query with predicate
            Store-->>HK: [HKSample] array
            HK->>HK: Map to HealthSampleDTO
            HK-->>Server: HealthDataResponse

            Server->>Server: Apply pagination
            Server->>Server: Sort by date descending
            Server->>Server: Log access event
            Server-->>CLI: 200 OK + JSON body
        end
    end

    CLI->>CLI: Parse JSON response
    CLI->>CLI: Convert to CSV/JSON
    CLI-->>User: Output to stdout/file
```

**Error Handling:**
- **401 Unauthorized**: Token expired or invalid → User needs to re-pair
- **400 Bad Request**: Invalid parameters → User needs to fix command
- **429 Too Many Requests**: Rate limit exceeded → User needs to wait
- **500 Server Error**: HealthKit error → Check logs

---

## 3. Device Pairing Flow

Complete flow of secure device pairing with QR code.

```mermaid
flowchart TD
    subgraph "iOS Device"
        A[Generate QR Code] --> B[Create 8-char code]
        B --> C[Generate pairing session]
        C --> D[Store in pendingSession]
        D --> E[Include server fingerprint]
        E --> F[Display QR code]
    end

    subgraph "User Action"
        F --> G[User copies QR code]
    end

    subgraph "Mac CLI"
        G --> H[healthsync scan]
        H --> I[Parse QR code]
        I --> J[Extract: host, port, code, fingerprint]
        J --> K[Generate client certificate]
        K --> L[Connect to server]
    end

    subgraph "TLS Handshake"
        L --> M{Server validates<br/>client certificate}
        M -->|Valid cert| N[Proceed]
        M -->|Invalid cert| O[Reject connection]
    end

    subgraph "Pairing Verification"
        N --> P[POST /api/v1/pair]
        P --> Q{Code matches?<br/>Constant-time compare}
        Q -->|No| R[Increment failed counter]
        R --> S{Too many attempts?}
        S -->|Yes| T[Lock out]
        S -->|No| U[Return: Invalid code]
        Q -->|Yes| V[Generate Bearer token]
        V --> W[Hash token with SHA256]
        W --> X[Store in SwiftData]
        X --> Y[Return: PairingResponse]
    end

    subgraph "Post-Pairing"
        Y --> Z[CLI stores token]
        Z --> AA[iOS shows: Paired Devices: 1]
    end

    style V fill:#e1ffe1
    style Y fill:#e1ffe1
    style AA fill:#e1ffe1
    style O fill:#ffe1e1
    style T fill:#ffe1e1
    style U fill:#fff4e1
```

**Security Features:**
- QR code expires in 5 minutes
- Maximum 5 failed attempts, then lockout
- Constant-time comparison prevents timing attacks
- Only token hash stored (never the token itself)
- Client name anonymized before storage

---

## 4. Certificate Lifecycle

Flow of TLS certificate creation, storage, and usage.

```mermaid
stateDiagram-v2
    [*] --> CheckKeychain: App starts

    CheckKeychain --> Exists: Certificate found
    CheckKeychain --> CreateNew: Not found

    Exists --> LoadCert: Load certificate
    Exists --> VerifyFingerprint: User verifies

    CreateNew --> GenerateKey: Generate ECDSA P-256 key
    GenerateKey --> StoreKey: Store in Keychain
    StoreKey --> BuildCert: Build self-signed cert
    BuildCert --> StoreCert: Store in Keychain
    StoreCert --> CreateIdentity: Create SecIdentity
    CreateIdentity --> CalculateFingerprint: SHA256 hash
    CalculateFingerprint --> [*]

    LoadCert --> CreateIdentity
    VerifyFingerprint --> [*]

    stateDiagram-v2
        [*] --> ServerStart: Server.start()
        ServerStart --> Listening: NWListener created
        Listening --> Connected: Client connects
        Connected --> Handshake: TLS 1.3 handshake
        Handshake --> Authenticated: mTLS success
        Handshake --> Rejected: Certificate invalid
        Authenticated --> Processing: Request routed
        Processing --> Listening: Request complete
        Rejected --> [*]
```

**Keychain Storage:**
- Private key stored with Secure Enclave (if available)
- Certificate stored separately
- Both encrypted at rest by iOS
- Access controlled by app entitlements

---

## 5. Error Recovery Flows

How the system handles various error conditions.

```mermaid
flowchart TD
    Start[User operation] --> Check{Check operation type}

    Check -->|Fetch data| Fetch[Validate token]
    Check -->|Pair device| Pair[Generate QR code]
    Check -->|Start server| Server[Load/create certificate]

    Fetch --> TokenValid{Token valid?}
    TokenValid -->|No| TokenError[401 Unauthorized]
    TokenValid -->|Yes| RateLimit{Rate limited?}

    RateLimit -->|Yes| RateError[429 Too Many Requests]
    RateLimit -->|No| HealthKit{HealthKit<br/>available?}

    HealthKit -->|No| HKError[503 Service Unavailable]
    HealthKit -->|Yes| Query[Query HealthKit]

    Query --> HasData{Data found?}
    HasData -->|No| NoData[200 OK, empty array]
    HasData -->|Yes| Success[200 OK, data]

    Pair --> Pending{Pending session<br/>exists?}
    Pending -->|No| NoSession[400 Bad Request]
    Pending -->|Yes| CodeCheck{Code valid?}

    CodeCheck -->|No| Attempts{Too many<br/>attempts?}
    Attempts -->|Yes| Locked[429 Locked]
    Attempts -->|No| InvalidCode[400 Invalid code]
    CodeCheck -->|Yes| Paired[200 OK, token]

    Server --> CertExists{Certificate<br/>exists?}
    CertExists -->|Yes| LoadCert[Load from Keychain]
    CertExists -->|No| CreateCert[Generate new cert]

    LoadCert --> CertError{Load successful?}
    CreateCert --> CertError{Create successful?}

    CertError -->|No| ServerError[500 Server Error]
    CertError -->|Yes| Running[Server running]

    style Success fill:#e1ffe1
    style Paired fill:#e1ffe1
    style Running fill:#e1ffe1
    style NoData fill:#fff4e1
    style TokenError fill:#ffe1e1
    style RateError fill:#ffe1e1
    style HKError fill:#ffe1e1
    style NoSession fill:#ffe1e1
    style InvalidCode fill:#fff4e1
    style Locked fill:#ffe1e1
    style ServerError fill:#ffe1e1
```

**HTTP Status Codes Used:**
- **200 OK**: Success
- **400 Bad Request**: Invalid input
- **401 Unauthorized**: Invalid/expired token
- **404 Not Found**: Unknown route
- **413 Payload Too Large**: Request body too large
- **429 Too Many Requests**: Rate limit exceeded
- **500 Server Error**: Internal error
- **503 Service Unavailable**: HealthKit unavailable

---

## 6. Data Transformation Pipeline

How health data transforms from HealthKit to CLI output.

```mermaid
flowchart LR
    subgraph "HealthKit Store"
        HK1[HKQuantitySample]
        HK2[HKCategorySample]
        HK3[HKWorkout]
    end

    subgraph "HealthKitService"
        Map1[HealthSampleMapper.mapSample]
    end

    subgraph "Network Transfer"
        DTO[HealthSampleDTO]
    end

    subgraph "CLI Output"
        CSV[CSV Format]
        JSON[JSON Format]
    end

    HK1 --> Map1
    HK2 --> Map1
    HK3 --> Map1

    Map1 --> DTO

    DTO --> CSV
    DTO --> JSON

    subgraph "DTO Structure"
        DTOFields[id]
        DTOFields[type]
        DTOFields[value]
        DTOFields[unit]
        DTOFields[startDate]
        DTOFields[endDate]
        DTOFields[sourceName]
    end
```

**Data Mappings:**

| HealthKit Type | DTO Type | Value Mapping |
|---------------|----------|---------------|
| Steps (Quantity) | steps | count |
| Heart Rate (Quantity) | heartRate | bpm |
| Sleep Analysis (Category) | sleep | value (asleep, inBed) |
| Workout | workout | duration + type |
| Distance (Quantity) | distance | meters |

---

## 7. Concurrency and Threading

How Swift 6 concurrency manages parallel operations.

```mermaid
graph TB
    subgraph "Main Thread (@MainActor)"
        UI[SwiftUI Views]
        AppState[AppState Updates]
    end

    subgraph "Actor 1: HealthKitService"
        HK1[fetchSamples]
        HK2[requestAuthorization]
    end

    subgraph "Actor 2: NetworkServer"
        NS1[start]
        NS2[handleConnection]
        NS3[route]
    end

    subgraph "Actor 3: PairingService"
        PS1[generateQRCode]
        PS2[handlePairRequest]
    end

    subgraph "System Frameworks"
        SF1[HealthKit Store]
        SF2[Network Framework]
        SF3[Keychain]
    end

    UI -.->|await| AppState
    AppState -->|await| HK1
    AppState -->|await| NS1
    AppState -->|await| PS1

    HK1 -->|Callbacks| SF1
    NS2 -->|async| SF2
    PS2 -->|sync| SF3

    style UI fill:#f0f0f0
    style AppState fill:#f0f0f0
    style HK1 fill:#e1f5ff
    style NS1 fill:#ffe1f5
    style PS1 fill:#fff4e1
```

**Concurrency Safety:**
- Actors prevent data races automatically
- `@MainActor` ensures UI updates on main thread
- `await` hops between execution contexts
- No manual thread management needed

---

## 8. Security Boundaries

Where security checks happen in the data flow.

```mermaid
flowchart TD
    Request[Incoming Request] --> TLS{TLS 1.3<br/>Handshake}
    TLS -->|Fail| Reject[Connection Rejected]
    TLS -->|Success| Auth{Bearer Token<br/>Valid?}

    Auth -->|No| Unauthorized[401 Unauthorized]
    Auth -->|Yes| Rate{Rate Limit<br/>OK?}

    Rate -->|No| Limited[429 Rate Limited]
    Rate -->|Yes| Public{Public<br/>Endpoint?}

    Public -->|Yes: /pair| HandlePair[Handle Pairing]
    Public -->|No| Protected{Protected<br/>Endpoint?}

    Protected -->|Yes| Validate{Request<br/>Valid?}
    Protected -->|No| NotFound[404 Not Found]

    Validate -->|No| BadRequest[400 Bad Request]
    Validate -->|Yes| Process[Process Request]

    HandlePair --> Audit1[Audit Log]
    Process --> Audit2[Audit Log]

    style Reject fill:#ffe1e1
    style Unauthorized fill:#ffe1e1
    style Limited fill:#fff4e1
    style BadRequest fill:#fff4e1
    style NotFound fill:#fff4e1
    style Audit1 fill:#e1ffe1
    style Audit2 fill:#e1ffe1
```

**Security Layers:**
1. **TLS 1.3**: Encryption and certificate validation
2. **Bearer Token**: Authentication for protected endpoints
3. **Rate Limiting**: DDoS protection (60 req/min)
4. **Input Validation**: Prevent injection attacks
5. **Audit Logging**: Track all access for security monitoring

---

## 9. Audit Trail Flow

How all health data access is logged.

```mermaid
flowchart LR
    subgraph "Events"
        E1[api.request]
        E2[healthkit.fetch]
        E3[auth.pair]
        E4[security.unauthorized_access]
        E5[security.rate_limit_exceeded]
    end

    subgraph "AuditService"
        Log[record:details:]
    end

    subgraph "Storage"
        Structured[Structured Logs]
        Private[Privacy-First]
    end

    E1 --> Log
    E2 --> Log
    E3 --> Log
    E4 --> Log
    E5 --> Log

    Log --> Structured
    Structured --> Private

    subgraph "Log Fields"
        F1[timestamp]
        F2[eventType]
        F3[requestId]
        F4[details]
    end

    subgraph "Privacy Rules"
        P1[No PII in logs]
        P2[Hash or omit health data]
        P3[Hash device names]
    end
```

**Logged Events:**
- Every API request
- Every HealthKit fetch
- All pairing attempts
- All security events (unauthorized access, rate limits)
- All errors and failures

---

**Data Flow Diagrams Version:** 1.0.0
**Last Updated:** 2026-01-07

---

For more details, see:
- [Architecture Overview](architecture.md)
- [API Documentation](api/)
- [Security Guide](../explanation/security.md)
