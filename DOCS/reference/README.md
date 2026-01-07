# Reference Documentation

**Technical Specifications and APIs**

---

## What Is Reference Documentation?

Reference docs contain **technical specifications** - exact information about APIs, parameters, return values, configuration options, etc.

**Characteristics:**
- ✅ Comprehensive and detailed
- ✅ Structured for lookup
- ✅ No explanations or tutorials
- ✅ Factual and concise
- ✅ Code-focused

---

## Reference Sections

### Architecture

| Document | Description |
|----------|-------------|
| [Architecture Overview](./architecture.md) | System design and layers |
| [Data Flow](./data-flow.md) | Request/response lifecycle |
| [Service Architecture](./services.md) | Actor-based service design |
| [Security Model](./security.md) | Encryption and authentication |

### APIs & Components

| Document | Description |
|----------|-------------|
| [HealthKitService API](./api/healthkit-service.md) | Health data access |
| [NetworkServer API](./api/network-server.md) | HTTP server endpoints |
| [PairingService API](./api/pairing-service.md) | Device pairing |
| [KeychainStore API](./api/keychain-store.md) | Secure storage |
| [AuditService API](./api/audit-service.md) | Logging and compliance |

### Data Models

| Document | Description |
|----------|-------------|
| [HealthDataType Enum](./models/health-data-type.md) | Supported health metrics |
| [HealthSampleDTO](./models/health-sample-dto.md) | Data transfer object |
| [SyncConfiguration](./models/sync-configuration.md) | User settings model |
| [PairingToken](./models/pairing-token.md) | Pairing credentials |

### Configuration

| Document | Description |
|----------|-------------|
| [Environment Variables](./config/env-vars.md) | CLI configuration |
| [Info.plist Keys](./config/info-plist.md) | iOS app permissions |
| [Entitlements](./config/entitlements.md) | Capabilities and access |
| [Build Settings](./config/build-settings.md) | Xcode configuration |

### CLI Commands

| Document | Description |
|----------|-------------|
| [CLI Overview](./cli/index.md) | Command-line tool introduction |
| [Command Reference](./cli/commands.md) | All commands and options |
| [Exit Codes](./cli/exit-codes.md) | Error codes and meanings |

---

## Finding What You Need

**By Component:**
- Need **HealthKit**? → [HealthKitService API](./api/healthkit-service.md)
- Need **networking**? → [NetworkServer API](./api/network-server.md)
- Need **security**? → [Security Model](./security.md)

**By Task:**
- Setting up → [Configuration](#configuration)
- Troubleshooting → [Exit Codes](./cli/exit-codes.md)
- Understanding → [Architecture](#architecture)

**By Format:**
- Quick lookup → [CLI Commands](#cli-commands)
- API details → [APIs & Components](#apis--components)
- Data structures → [Data Models](#data-models)

---

## Reference Format

Each reference page follows this structure:

```markdown
# [Component Name]

**Type:** Actor/Class/Struct/Enum/Protocol
**Module:** Services/Models/Utilities/etc.
**Availability:** iOS 26.0+

## Declaration
```swift
[Swift declaration]
```

## Overview
[Brief description of purpose]

## Topics

### [Property/Method 1]
[Signature]
[Description]
[Parameters]
[Returns]
[Throws]

### [Property/Method 2]
[...]

## Relationships
- Inherits from: ...
- Conforms to: ...
- Used by: ...

## See Also
- [Related Component]
- [Discussion]
```

---

## Quick Reference Cards

### HealthSampleDTO

```swift
struct HealthSampleDTO: Codable, Sendable {
    let id: UUID              // Unique identifier
    let type: String          // Data type name
    let value: Double         // Measurement value
    let unit: String          // Unit (e.g., "count", "bpm")
    let startDate: Date       // Sample start time
    let endDate: Date         // Sample end time
    let sourceName: String    // Data source
    let metadata: [String: String]?  // Additional info
}
```

### Server Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/status` | GET | Server health check |
| `/api/v1/pairing` | POST | Device pairing |
| `/api/v1/health/data` | POST | Fetch health data |
| `/api/v1/health/types` | GET | List available types |

### CLI Commands

```bash
healthsync discover      # Find iOS devices
healthsync scan          # Scan QR code from clipboard
healthsync pair          # Pair with iOS device
healthsync fetch         # Fetch health data
healthsync status        # Check connection status
healthsync types         # List enabled data types
healthsync version       # Show version info
```

---

## See Also

- **[Tutorials](../tutorials/)** - Learning-oriented lessons
- **[How-To Guides](../how-to/)** - Goal-oriented instructions
- **[Explanation](../explanation/)** - Conceptual understanding
- **[Diataxis Framework](https://diataxis.fr/)** - About this documentation system

---

**Reference Index Version:** 1.0.0
**Last Updated:** 2026-01-07
