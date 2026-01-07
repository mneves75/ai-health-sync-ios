# Chapter 9: macOS CLI Companion

**Building Command-Line Tools with Swift**

---

## Learning Objectives

After this chapter, you will be able to:

- ✅ Understand CLI architecture
- ✅ Parse command-line arguments
- ✅ Implement subcommands
- ✅ Format output (CSV, JSON)
- ✅ Handle errors gracefully

---

## The Simple Explanation

### What Is a CLI?

**CLI (Command-Line Interface)** = Text-based interaction with your computer.

```
GUI vs CLI:
┌─────────────────┐                $ healthsync status
│   [Connect]     │                Server: Running
│   [Sync]        │                Port: 8443
│   [Settings]    │                Devices: 2
└─────────────────┘
     Click buttons                 Type commands
```

**Why CLI for this app?**
- Fast for automation
- Scriptable
- Works over SSH
- Lightweight
- Developer-friendly

---

## CLI Architecture

### The Command Pattern

```
User types command
    ↓
ArgumentParser parses
    ↓
Command identified
    ↓
Command executed
    ↓
Output formatted
    ↓
User sees result
```

### Our Commands

| Command | Description |
|---------|-------------|
| `healthsync discover` | Find iOS devices on network |
| `healthsync scan` | Scan QR code from clipboard |
| `healthsync pair` | Pair with iOS device |
| `healthsync fetch` | Fetch health data |
| `healthsync status` | Check connection status |
| `healthsync types` | List enabled data types |
| `healthsync version` | Show version info |

---

## Package Structure

**File:** `macOS/HealthSyncCLI/Package.swift`

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HealthSyncCLI",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "HealthSyncCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "HealthSyncCLITests",
            dependencies: ["HealthSyncCLI"]
        )
    ]
)
```

**What this defines:**
- Package name
- Minimum macOS version
- Dependencies (ArgumentParser)
- Build targets

---

## ArgumentParser

### What Is ArgumentParser?

**ArgumentParser** = Apple's library for parsing CLI arguments:

```swift
// Without ArgumentParser
let args = CommandLine.arguments
guard args.count >= 2 else { print("Usage: ..."); exit(1) }
let command = args[1]
// Manual parsing... painful!

// With ArgumentParser
@ArgumentParser
struct CLI {
    var run() throws {
        // Automatic parsing!
    }
}
```

### Basic Command

```swift
import ArgumentParser

@main
struct HealthSyncCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "healthsync",
        abstract: "Fetch health data from iOS devices",
        discussion: """
        HealthSync CLI connects to your iOS Health Sync app
        and exports your health data to CSV or JSON format.
        """,
        version: "1.0.0"
    )

    @Option(name: .short, help: "Output format (csv or json)")
    var format: OutputFormat = .csv

    @Option(name: .short, help: "Output file path")
    var output: String?

    func run() async throws {
        print("HealthSync CLI v\(Self.configuration.version)")
    }
}
```

**Result:**
```bash
$ healthsync --help
USAGE: healthsync [--format <format>] [--output <output>]

OPTIONS:
  -f, --format <format>     Output format (csv or json)
  -o, --output <output>     Output file path
  -h, --help                Show help information
```

---

## Subcommands

### Defining Subcommands

```swift
@main
struct HealthSyncCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "healthsync",
        abstract: "Fetch health data from iOS devices",
        subcommands: [
            DiscoverCommand.self,
            ScanCommand.self,
            PairCommand.self,
            FetchCommand.self,
            StatusCommand.self,
            TypesCommand.self,
        ]
    )
}
```

### Discover Command

```swift
struct DiscoverCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Discover HealthSync servers on the network"
    )

    @Option(name: .long, help: "Search duration in seconds")
    var duration: Int = 5

    func run() async throws {
        print("🔍 Searching for HealthSync servers...")

        let client = NetworkClient()
        let servers = await client.discoverServers(duration: Double(duration))

        if servers.isEmpty {
            print("❌ No servers found")
            print("   Make sure the iOS app is running and server is started")
        } else {
            print("✅ Found \(servers.count) server(s):")
            for server in servers {
                print("   • \(server.name) (\(server.host):\(server.port))")
            }
        }
    }
}
```

**Usage:**
```bash
$ healthsync discover
🔍 Searching for HealthSync servers...
✅ Found 1 server(s):
   • HealthSync-A3F2 (192.168.1.100:8443)
```

### Scan Command

```swift
struct ScanCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Scan QR code from clipboard"
    )

    func run() async throws {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        guard let qrString = pasteboard.string(forType: .string) else {
            throw CLIError.noClipboardData
        }

        guard let qrCode = parseQRCode(qrString) else {
            throw CLIError.invalidQRCode
        }

        print("📱 QR Code detected:")
        print("   Host: \(qrCode.host)")
        print("   Port: \(qrCode.port)")
        print("   Code: \(qrCode.code)")
        print("   Expires: \(qrCode.expiresAt)")

        // Store for pairing
        try storeQRCode(qrCode)

        print("✅ QR code saved. Run 'healthsync pair' to complete pairing.")
        #else
        throw CLIError.notSupported
        #endif
    }
}
```

**Usage:**
```bash
# On iOS, tap "Copy QR Code"
# Then on Mac:
$ healthsync scan
📱 QR Code detected:
   Host: 192.168.1.100
   Port: 8443
   Code: ABC12345
   Expires: 2026-01-07 15:35:00
✅ QR code saved. Run 'healthsync pair' to complete pairing.
```

---

## The Fetch Command

### Command Definition

```swift
struct FetchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Fetch health data from paired device"
    )

    @Option(name: .long, help: "Start date (ISO8601 format)")
    var startDate: Date?

    @Option(name: .long, help: "End date (ISO8601 format)")
    var endDate: Date?

    @Option(name: .long, help: "Number of days to fetch")
    var days: Int?

    @Option(name: .short, help: "Data types to fetch")
    var types: [String] = []

    @Option(name: .short, help: "Output format")
    var format: OutputFormat = .csv

    @Option(name: .short, help: "Output file path")
    var output: String?

    @Option(name: .long, help: "Maximum samples")
    var limit: Int = 1000

    @Flag(name: .long, help: "Include all data types")
    var all: Bool = false

    func run() async throws {
        // Implementation...
    }
}
```

### Date Parsing

```swift
extension FetchCommand {
    func getDateRange() throws -> (start: Date, end: Date) {
        let end = endDate ?? Date()

        let start: Date
        if let days {
            start = Calendar.current.date(byAdding: .day, value: -days, to: end) ?? end
        } else if let startDate {
            start = startDate
        } else {
            // Default: last 30 days
            start = Calendar.current.date(byAdding: .day, value: -30, to: end) ?? end
        }

        guard start < end else {
            throw CLIError.invalidDateRange
        }

        return (start, end)
    }
}
```

### Data Fetching

```swift
func run() async throws {
    print("🔄 Fetching health data...")

    // Load stored pairing info
    let pairing = try loadPairing()
    let client = NetworkClient(
        host: pairing.host,
        port: pairing.port,
        fingerprint: pairing.fingerprint,
        token: pairing.token
    )

    // Determine date range
    let (start, end) = try getDateRange()

    // Determine types
    let typesToFetch: [String]
    if all {
        typesToFetch = try await client.getTypes()
    } else if types.isEmpty {
        typesToFetch = try await client.getTypes()
    } else {
        typesToFetch = types
    }

    print("   Date range: \(start.formatted()) to \(end.formatted())")
    print("   Types: \(typesToFetch.joined(separator: ", "))")

    // Fetch data
    let response = try await client.fetchData(
        types: typesToFetch,
        startDate: start,
        endDate: end,
        limit: limit
    )

    // Format output
    let outputData: Data
    switch format {
    case .csv:
        outputData = try formatAsCSV(response.samples)
    case .json:
        outputData = try formatAsJSON(response.samples)
    }

    // Write to file or stdout
    if let outputPath = output {
        try outputData.write(to: URL(fileURLWithPath: outputPath))
        print("✅ Saved to \(outputPath)")
    } else {
        FileHandle.standardOutput.write(outputData)
        print("✅ Fetched \(response.returnedCount) samples")
    }
}
```

---

## Output Formatting

### CSV Format

```swift
func formatAsCSV(_ samples: [HealthSampleDTO]) throws -> Data {
    var csv = "Type,Value,Unit,Start Date,End Date,Source\n"

    for sample in samples {
        let row = [
            sample.type,
            String(sample.value),
            sample.unit,
            formatDate(sample.startDate),
            formatDate(sample.endDate),
            escapeCSV(sample.sourceName)
        ].map { escapeCSV($0) }.joined(separator: ",")

        csv += row + "\n"
    }

    return csv.data(using: .utf8)!
}

func escapeCSV(_ field: String) -> String {
    if field.contains(",") || field.contains("\"") || field.contains("\n") {
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
    return field
}
```

**Output:**
```csv
Type,Value,Unit,Start Date,End Date,Source
steps,8432,count,2025-01-07T08:00:00Z,2025-01-07T09:00:00Z,"iPhone 15 Pro"
heartRate,72.0,count/min,2025-01-07T08:05:00Z,2025-01-07T08:05:00Z,"Apple Watch"
```

### JSON Format

```swift
func formatAsJSON(_ samples: [HealthSampleDTO]) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    return try encoder.encode(samples)
}
```

**Output:**
```json
[
  {
    "id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
    "type": "steps",
    "value": 8432.0,
    "unit": "count",
    "startDate": "2025-01-07T08:00:00Z",
    "endDate": "2025-01-07T09:00:00Z",
    "sourceName": "iPhone 15 Pro",
    "metadata": null
  }
]
```

---

## Error Handling

### Error Types

```swift
enum CLIError: Error, LocalizedError {
    case noPairingFound
    case pairingExpired
    case connectionFailed(String)
    case authenticationFailed
    case noClipboardData
    case invalidQRCode
    case invalidDateRange
    case notSupported

    var errorDescription: String? {
        switch self {
        case .noPairingFound:
            return "No pairing found. Run 'healthsync scan' and 'healthsync pair' first."
        case .pairingExpired:
            return "Pairing has expired. Please re-pair with your device."
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .authenticationFailed:
            return "Authentication failed. Your pairing may have been revoked."
        case .noClipboardData:
            return "No QR code found in clipboard."
        case .invalidQRCode:
            return "Invalid QR code format."
        case .invalidDateRange:
            return "Invalid date range. Start date must be before end date."
        case .notSupported:
            return "This command is not supported on this platform."
        }
    }
}
```

### Error Display

```swift
func run() async throws {
    do {
        try await performFetch()
    } catch let error as CLIError {
        print("❌ Error: \(error.localizedDescription)")
        throw ExitCode.failure
    } catch {
        print("❌ Unexpected error: \(error)")
        throw ExitCode.failure
    }
}
```

---

## Exercises

### 🟢 Beginner: Create a Status Command

**Task:** Implement the status command:

```swift
struct StatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show connection status"
    )

    func run() async throws {
        // Check if pairing exists
        // Show server status
        // Show token expiration
    }
}
```

---

### 🟡 Intermediate: Add Progress Indicator

**Task:** Add progress indicator for large fetches:

```swift
func fetchWithProgress() async throws -> HealthDataResponse {
    // Show: Fetching [=====>     ] 42%
}
```

---

### 🔴 Advanced: Add Export Subcommand

**Task:** Create dedicated export command with options:

```swift
struct ExportCommand: AsyncParsableCommand {
    @Option(name: .long, help: "Format: csv, json, xml")
    var format: ExportFormat

    @Option(name: .long, help: "Compression: none, gzip")
    var compression: CompressionType

    // Implementation
}
```

---

## Common Pitfalls

### Pitfall 1: Not handling SIGINT

```swift
// WRONG: Can't cancel
func run() async throws {
    for await item in hugeStream {
        process(item)  // Can't stop!
    }
}

// RIGHT: Handle cancellation
func run() async throws {
    try withTaskCancellationHandler(
        operation: {
            for await item in hugeStream {
                try Task.checkCancellation()
                process(item)
            }
        },
        onCancel: {
            print("\n⚠️ Cancelled by user")
        }
    )
}
```

### Pitfall 2: Blocking on async

```swift
// WRONG: Blocking main thread
func run() async throws {
    let data = try! Data(contentsOf: url)  // Blocks!
}

// RIGHT: Async API
func run() async throws {
    let (data, _) = try await URLSession.shared.data(from: url)
}
```

### Pitfall 3: Poor error messages

```swift
// WRONG: Vague error
throw CLIError.failed

// RIGHT: Helpful error
throw CLIError.connectionFailed("""
    Cannot connect to server at \(host):\(port)
    Possible causes:
    - Server is not running
    - Network is unavailable
    - Firewall is blocking connection
    """)
```

---

## Key Takeaways

### ✅ CLI Patterns

| Pattern | Purpose |
|---------|---------|
| **AsyncParsableCommand** | Async command support |
| **Subcommands** | Organized functionality |
| **Option** | Named parameters |
| **Flag** | Boolean switches |
| **Argument** | Positional values |

---

## Coming Next

In **Chapter 10: Testing Your Code**, you'll learn:

- Swift Testing framework
- Protocol-based mocking
- Unit testing services
- Integration testing

---

**Next Chapter:** [Testing Your Code](10-testing.md) →
