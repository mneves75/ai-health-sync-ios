# Architecture Overview

**iOS Health Sync App - System Design and Component Interaction**

---

## High-Level Architecture

```mermaid
graph TB
    subgraph "iOS App (iPhone)"
        UI[SwiftUI Views]
        AppState[AppState Actor]
        HealthKit[HealthKitService Actor]
        Network[NetworkServer Actor]
        Pairing[PairingService Actor]
        Certs[CertificateService]
        Audit[AuditService]
        Storage[SwiftData Models]

        UI --> AppState
        AppState --> HealthKit
        AppState --> Network
        AppState --> Pairing
        AppState --> Storage

        HealthKit --> HealthKitStore[(HealthKit Framework)]

        Network --> Pairing
        Network --> HealthKit
        Network --> Certs
        Network --> Audit

        Pairing --> Keychain[(Keychain)]
        Certs --> Keychain

        HealthKit --> Audit
        Network --> Audit
        Pairing --> Audit
    end

    subgraph "macOS CLI"
        CLI[healthsync Command]
        Client[HTTP Client]
        CertStore[Certificate Store]
    end

    CLI --> Client
    Client --> CertStore

    Client <--->|mTLS 1.3| Network

    style HealthKit fill:#e1f5ff
    style Network fill:#ffe1f5
    style Pairing fill:#fff4e1
    style Certs fill:#e1ffe1
    style Audit fill:#f5e1ff
```

---

## Component Details

<details>
<summary>📱 Presentation Layer (SwiftUI)</summary>

```mermaid
classDiagram
    class ContentView {
        +ObservedObject appState: AppState
    }

    class QRCodeView {
        +String qrCodeString
    }

    class HealthDataTypeToggle {
        +Bool isEnabled
    }

    ContentView --> AppState
    ContentView --> QRCodeView
    ContentView --> HealthDataTypeToggle
```

**Purpose:** User interface for the iOS app
**Technologies:** SwiftUI 5.0+, @Observation macro
**Key Responsibilities:**
- Display server status and QR code
- Toggle health data types for sharing
- Show pairing status

</details>

<details>
<summary>🔧 Application Layer</summary>

```mermaid
classDiagram
    class AppState {
        @MainActor
        +Published isServerRunning: Bool
        +Published serverPort: Int
        +Published qrCodeString: String
        +Published pairedDevices: [PairedDevice]
        +HealthKitService healthService
        +NetworkServer networkServer
        +PairingService pairingService
        +startServer() async
        +stopServer()
        +generateQRCode()
    }

    class HealthKitService {
        +fetchSamples() async
        +requestAuthorization() async
    }

    class NetworkServer {
        +start() async throws
        +stop()
        +port: Int
        +certificateFingerprint: String
    }

    class PairingService {
        +generatePairingToken() async
        +verifyPairingToken() async
    }

    AppState --> HealthKitService
    AppState --> NetworkServer
    AppState --> PairingService
```

**Purpose:** Business logic and state management
**Key Pattern:** Actor-based concurrency
**Technologies:** Swift 6 async/await, @MainActor

</details>

<details>
<summary>💾 Data Layer</summary>

```mermaid
classDiagram
    class HealthSample {
        +UUID id
        +Date startDate
        +Date endDate
        +Double value
        +String unit
        +String sourceName
    }

    class PairedDevice {
        @Attribute
        +UUID id
        +String certificateFingerprint
        +Date pairedAt
        +Date lastSeen
    }

    class SyncConfiguration {
        @Attribute
        +UUID id
        +Set~HealthDataType~ enabledTypes
        +Bool requireAuthentication
    }
```

**Purpose:** Data persistence and models
**Technology:** SwiftData (iOS 17+)
**Pattern:** Soft deletes with `deletedAt` timestamp

</details>

<details>
<summary>🌐 Network Layer</summary>

```mermaid
sequenceDiagram
    participant CLI as macOS CLI
    participant Server as NetworkServer
    participant Pairing as PairingService
    participant HealthKit as HealthKitService
    participant HK as HealthKit Store

    CLI->>Server: TCP + mTLS Handshake
    Server->>Pairing: Verify Certificate

    alt Certificate Not Paired
        Pairing-->>Server: Reject
        Server-->>CLI: 401 Unauthorized
    else Certificate Paired
        Pairing-->>Server: OK
        Server->>HealthKit: fetchSamples(types, dates)
        HealthKit->>HK: Query with predicate
        HK-->>HealthKit: [HKSample]
        HealthKit->>HealthKit: Map to DTO
        HealthKit-->>Server: HealthDataResponse
        Server-->>CLI: JSON Response
    end
```

**Security Features:**
- **TLS 1.3 only** - Minimum protocol version enforced
- **Mutual authentication** - Both client and server present certificates
- **Certificate pinning** - Server validates client certificate fingerprint
- **Local network only** - Bonjour discovery on `.local` domain

</details>

---

## Data Flow

### Fetching Health Data

```mermaid
flowchart TD
    Start[CLI: healthsync fetch] --> Parse[Parse arguments]
    Parse --> Discover[Discover device via Bonjour]
    Discover --> Connect[TCP + mTLS connection]

    Connect --> Auth{Certificate paired?}

    Auth -->|No| Error[401 Unauthorized]
    Auth -->|Yes| BuildRequest[Build HTTP POST request]

    BuildRequest --> Send[Send to /api/v1/health/data]
    Send --> Receive[NetworkServer receives]

    Receive --> Validate[Validate request & rate limit]
    Validate --> Fetch[HealthKitService.fetchSamples]

    Fetch --> Query[Query HealthKit with predicate]
    Query --> Map[Map HKSample → DTO]

    Map --> Sort[Sort by date descending]
    Sort --> Paginate[Apply offset/limit]
    Paginate --> Response[Return HealthDataResponse]

    Response --> Audit[Log access in AuditService]
    Audit --> SendResponse[Send JSON to CLI]
    SendResponse --> Output[CLI outputs CSV/JSON]

    style Fetch fill:#e1f5ff
    style Query fill:#ffe1f5
    style Map fill:#fff4e1
    style Audit fill:#f5e1ff
```

---

### Device Pairing Flow

```mermaid
flowchart TD
    Start[iOS: Start Server] --> Generate[Generate TLS certificate]
    Generate --> StoreCert[Store in Keychain]
    StoreCert --> Display[Display QR Code]

    Start2[CLI: healthsync scan] --> ReadQR[Read QR from clipboard]
    ReadQR --> ParseToken[Parse pairing token]
    ParseToken --> Connect[Connect to server]

    Connect --> PresentCert[Present client certificate]
    PresentCert --> Validate{Server validates}

    Validate -->|Reject| Error[Connection refused]
    Validate -->|Accept| StoreFingerprint[Store fingerprint in Keychain]

    StoreFingerprint --> Success[Pairing complete]
    Success --> Data[Can now fetch health data]

    style Generate fill:#e1ffe1
    style Display fill:#fff4e1
    style Connect fill:#e1f5ff
    style StoreFingerprint fill:#ffe1f5
```

---

<details>
<summary>🧵 Threading Model</summary>

```mermaid
graph TB
    subgraph "Main Thread (@MainActor)"
        UI[SwiftUI Views]
        AppState[AppState Updates]
    end

    subgraph "Background Actors"
        HealthKit[HealthKitService]
        Network[NetworkServer]
        Pairing[PairingService]
    end

    subgraph "System Frameworks"
        HKStore[HealthKit Store]
        NetworkFramework[Network Framework]
        Keychain[Keychain Storage]
    end

    UI -.->|MainActor.run| AppState
    AppState -->|await| HealthKit
    AppState -->|await| Network
    AppState -->|await| Pairing

    HealthKit -->|Callbacks wrapped| HKStore
    Network -->|async callbacks| NetworkFramework
    Pairing -->|synchronous| Keychain

    style UI fill:#f0f0f0
    style AppState fill:#f0f0f0
```

**Key Points:**
- SwiftUI runs on `@MainActor` (main thread)
- All services are actors (thread-safe by default)
- `await` automatically hops between execution contexts
- No manual thread management required

</details>

---

<details>
<summary>🔒 Security Architecture</summary>

```mermaid
graph TB
    subgraph "Certificate-Based Security"
        A1[Server Certificate]
        A2[Client Certificate]
        A3[Mutual TLS 1.3]
    end

    subgraph "Certificate Lifecycle"
        B1[CertificateService.loadOrCreateIdentity]
        B2[Store in Keychain]
        B3[Pairing via QR Code]
        B4[Fingerprint Verification]
    end

    subgraph "Runtime Security"
        C1[Rate Limiting: 60 req/min]
        C2[Request Size Limits: 1MB max]
        C3[Timeout: 10s per request]
        C4[Audit Logging]
    end

    B1 --> B2 --> B3 --> B4
    A1 --> A3 --> A2
    C1 & C2 & C3 & C4

    style A1 fill:#e1ffe1
    style A2 fill:#e1ffe1
    style A3 fill:#ffe1f5
```

</details>

---

<details>
<summary>💾 Persistence Strategy</summary>

```mermaid
graph TB
    subgraph "SwiftData (SQLite)"
        Models[SwiftData Models]
        Config[SyncConfiguration]
        Devices[PairedDevice]
    end

    subgraph "Keychain (Encrypted)"
        Certs[TLS Certificates]
        Keys[Private Keys]
        Fingerprints[Paired Device Fingerprints]
    end

    subgraph "Audit Log (Append-Only)"
        Logs[Structured Audit Logs]
    end

    Models --> Config
    Models --> Devices

    Config -.->|User defaults| UI
    Devices -.->|List| UI

    Certs --> Network[Network Server]
    Keys --> Network
    Fingerprints --> Pairing[Pairing Service]

    HealthKit[HealthKit Access] --> Logs
    Network --> Logs
    Pairing --> Logs
```

</details>

---

## Error Handling Strategy

```mermaid
graph TB
    subgraph "Error Sources"
        E1[HealthKit Errors]
        E2[Network Errors]
        E3[Certificate Errors]
        E4[Validation Errors]
    end

    subgraph "Error Handling"
        H1[Log to AuditService]
        H2[Return User-Friendly Message]
        H3[Graceful Degradation]
        H4[Retry with Backoff]
    end

    subgraph "User Communication"
        U1[Alert/Toast]
        U2[Error Message in UI]
        U3[Log Entry]
    end

    E1 --> H1 --> H3 --> U2
    E2 --> H1 --> H4 --> U2
    E3 --> H1 --> U1
    E4 --> H1 --> U2

    All --> H3
    All --> U3
```

---

## Technology Stack

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **UI** | SwiftUI | 5.0+ | Declarative interface |
| **State** | @Observation macro | iOS 17+ | Automatic state updates |
| **Data** | SwiftData | iOS 17+ | Persistence |
| **Health** | HealthKit | iOS 17+ | Health data access |
| **Network** | Network Framework | iOS 17+ | TLS server |
| **Crypto** | CryptoKit | iOS 17+ | Certificate handling |
| **Storage** | Keychain | - | Secure certificate storage |
| **Logging** | os.logger | - | Structured logging |
| **CLI** | Swift Package Manager | 6.0+ | Command-line tool |

---

## Design Patterns Used

1. **Actor Pattern** - All services are actors for thread safety
2. **Dependency Injection** - Services injected via init
3. **Protocol-Oriented** - `HealthStoreProtocol` for testability
4. **Repository Pattern** - SwiftData models abstract data access
5. **Observer Pattern** - @Observation for UI updates
6. **Strategy Pattern** - Pluggable identity providers for certificates

---

## See Also

- **[Swift 6 Concurrency](../learn/03-swift6.md)** - How actors work
- **[Network Server API](./api/network-server.md)** - Server endpoints
- **[Security Model](./security.md)** - Certificate-based pairing
- **[Data Flow](./data-flows.md)** - Request/response lifecycle

---

**Architecture Documentation Version:** 1.0.0
**Last Updated:** 2026-01-07
**App Version:** 1.0.0
