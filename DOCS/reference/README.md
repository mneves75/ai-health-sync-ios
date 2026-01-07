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
| [Data Flows](./data-flows.md) | Request/response lifecycle |
| [Security Model](../learn/07-security.md) | Encryption and authentication |
| [Networking](../learn/08-networking.md) | HTTP server and TLS |

### APIs & Components

| Document | Description |
|----------|-------------|
| [HealthKitService API](./api/healthkit-service-api.md) | Health data access |
| [HealthKit Integration](../learn/06-healthkit.md) | HealthKit concepts |
| [CLI Reference](../learn/09-cli.md) | Command-line tool |

### Learning Resources

For in-depth explanations, see the [Learning Guide](../learn/00-welcome.md):

| Topic | Description |
|-------|-------------|
| [Swift 6 Concurrency](../learn/03-swift6.md) | Actor-based design |
| [SwiftUI](../learn/04-swiftui.md) | UI framework patterns |
| [SwiftData](../learn/05-swiftdata.md) | Persistence layer |
| [Testing](../learn/10-testing.md) | Test strategies |

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
- **[Learning Guide](../learn/00-welcome.md)** - Conceptual understanding
- **[Diataxis Framework](https://diataxis.fr/)** - About this documentation system

---

**Reference Index Version:** 1.0.0
**Last Updated:** 2026-01-07
