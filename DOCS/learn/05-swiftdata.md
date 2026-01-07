# Chapter 5: Persisting Data with SwiftData

**Storing Data on Device**

---

## Learning Objectives

After this chapter, you will be able to:

- ✅ Understand SwiftData and @Model
- ✅ Create data models
- ✅ Query data
- ✅ Handle relationships
- ✅ Perform migrations

---

## The Simple Explanation

### What Is Data Persistence?

**Persistence** means saving data so it survives app restarts.

```
Without Persistence:              With Persistence:
App opens → Empty data            App opens → Previous data
User enters data                   User sees previous data
App closes                         App closes
App opens → Empty data again!      App opens → Data is still there!
```

**SwiftData** is Apple's modern framework for data persistence:

```
Your Code
    ↓
SwiftData
    ↓
SQLite (on disk)
```

### Why SwiftData?

| Feature | SwiftData | Core Data | UserDefaults |
|---------|-----------|-----------|---------------|
| Type safety | ✅ | ❌ | ❌ |
| Swift-first | ✅ | ❌ | ✅ |
| Relationships | ✅ | ✅ | ❌ |
| Queries | ✅ | ✅ | ❌ |
| Migrations | ✅ | ✅ | ❌ |
| Cloud sync | ✅ | ✅ | ❌ |

---

## SwiftData Basics

### @Model Macro

The `@Model` macro creates a persistent data model:

```swift
import SwiftData

@Model
final class SyncConfiguration {
    var enabledTypesCSV: String
    var lastExportAt: Date?
    var createdAt: Date
}
```

**What `@Model` does:**
- Generates persistence code
- Creates schema information
- Enables querying
- Handles change tracking

### Model Types

**Classes only (not structs):**

```swift
// ✅ CORRECT: Class
@Model
final class MyModel {
    var name: String
}

// ❌ WRONG: Struct
@Model
struct MyModel {  // Error!
    var name: String
}
```

**Why classes:**
- Reference semantics
- Mutable state
- Relationship tracking

---

## In Our Code: Data Models

**File:** `Core/Models/PersistenceModels.swift`

### SyncConfiguration

```swift
@Model
final class SyncConfiguration {
    var enabledTypesCSV: String = HealthDataType.allCases
        .map(\.rawValue)
        .joined(separator: ",")
    var lastExportAt: Date?
    var createdAt: Date = Date()

    var enabledTypes: [HealthDataType] {
        get {
            enabledTypesCSV.split(separator: ",")
                .compactMap { HealthDataType(rawValue: String($0)) }
        }
        set {
            enabledTypesCSV = newValue.map(\.rawValue).joined(separator: ",")
        }
    }
}
```

**Breaking it down:**

1. **Stored property** (what's saved):
```swift
var enabledTypesCSV: String = "steps,heartRate,..."
```

2. **Computed property** (convenient access):
```swift
var enabledTypes: [HealthDataType] {
    get { /* parse CSV to array */ }
    set { /* convert array to CSV */ }
}
```

3. **Optional date:**
```swift
var lastExportAt: Date?  // nil means never exported
```

4. **Default value:**
```swift
var createdAt: Date = Date()  // Set when created
```

### PairedDevice

```swift
@Model
final class PairedDevice {
    var name: String
    var tokenHash: String
    var createdAt: Date
    var expiresAt: Date
    var lastSeenAt: Date?
    var isActive: Bool
}
```

**Why hash the token?**
```swift
// Store hash instead of raw token
var tokenHash: String = SHA256.hash(token)

// If database is compromised:
// - Attacker gets hash, not token
// - Can't reverse hash to get token
// - Token still works (we compare hashes)
```

**Security pattern:**
```
Raw Token (never stored)
    ↓
SHA256 Hash
    ↓
Store in SwiftData
```

### AuditEventRecord

```swift
@Model
final class AuditEventRecord {
    var eventType: String
    var timestamp: Date
    var detailJSON: String
}
```

**Why JSON string?**
```swift
// Flexible details
var detailJSON: String = """
{
    "userId": "123",
    "action": "login",
    "ip": "192.168.1.1"
}
"""

// Easy to add new fields without changing schema
```

---

## ModelContainer Setup

**File:** `App/iOS_Health_Sync_AppApp.swift`

```swift
@main
struct iOS_Health_Sync_AppApp: App {
    var sharedModelContainer: ModelContainer = {
        // Define schema
        let schema = Schema([
            SyncConfiguration.self,
            PairedDevice.self,
            AuditEventRecord.self
        ])

        // Configure storage
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false  // Persist to disk
        )

        // Create container
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

**Breaking it down:**

1. **Schema definition:**
```swift
let schema = Schema([
    SyncConfiguration.self,
    PairedDevice.self,
    AuditEventRecord.self
])
```

2. **Configuration:**
```swift
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false  // false = save to disk
)
```

3. **Container creation:**
```swift
return try ModelContainer(for: schema, configurations: [modelConfiguration])
```

4. **Attach to view hierarchy:**
```swift
.modelContainer(sharedModelContainer)
```

---

## Using SwiftData in Views

### ModelContext

`ModelContext` is your gateway to SwiftData:

```swift
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        // Use modelContext to access data
    }
}
```

### Querying Data

**Fetch all items:**

```swift
@Query private var configurations: [SyncConfiguration]

var body: some View {
    List(configurations) { config in
        Text(config.enabledTypesCSV)
    }
}
```

**Custom query:**

```swift
@Query(filter: #Predicate<PairedDevice> { device in
    device.isActive == true
}, sort: \PairedDevice.createdAt, order: .reverse) var activeDevices: [PairedDevice]
```

### Creating Data

```swift
let newDevice = PairedDevice(
    name: "My iPhone",
    tokenHash: hashedToken,
    createdAt: Date(),
    expiresAt: expirationDate,
    lastSeenAt: nil,
    isActive: true
)

modelContext.insert(newDevice)
```

### Updating Data

```swift
if let device = activeDevices.first {
    device.lastSeenAt = Date()
    try? modelContext.save()
}
```

### Deleting Data

```swift
modelContext.delete(device)
try? modelContext.save()
```

---

## In Our Code: AppState Usage

**File:** `App/AppState.swift:55-69`

```swift
init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    // ... other init code ...

    let context = modelContainer.mainContext
    do {
        if let existing = try context.fetch(FetchDescriptor<SyncConfiguration>()).first {
            self.syncConfiguration = existing
        } else {
            let newConfig = SyncConfiguration()
            context.insert(newConfig)
            try context.save()
            self.syncConfiguration = newConfig
        }
    } catch {
        AppLoggers.app.error("Failed to load or create SyncConfiguration")
        self.syncConfiguration = SyncConfiguration()
    }
}
```

**What's happening:**

1. **Get context:**
```swift
let context = modelContainer.mainContext
```

2. **Fetch existing:**
```swift
if let existing = try context.fetch(FetchDescriptor<SyncConfiguration>()).first
```

3. **Create if needed:**
```swift
let newConfig = SyncConfiguration()
context.insert(newConfig)
try context.save()
```

4. **Store reference:**
```swift
self.syncConfiguration = existing (or newConfig)
```

### Saving Changes

**File:** `App/AppState.swift:138-143`

```swift
func toggleType(_ type: HealthDataType, enabled: Bool) {
    var types = syncConfiguration.enabledTypes
    // ... modify types ...
    syncConfiguration.enabledTypes = types

    do {
        try modelContainer.mainContext.save()
    } catch {
        AppLoggers.app.error("Failed to save type toggle")
    }
}
```

**Automatic change tracking:**
- Modify `syncConfiguration.enabledTypes`
- SwiftData detects the change
- Call `context.save()` to persist

---

## FetchDescriptor

**FetchDescriptor** describes what to fetch:

```swift
// Fetch all
let descriptor = FetchDescriptor<SyncConfiguration>()

// With predicate
let descriptor = FetchDescriptor<PairedDevice>(
    predicate: #Predicate { $0.isActive == true }
)

// With sorting
let descriptor = FetchDescriptor<PairedDevice>(
    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
)

// With limit and offset
let descriptor = FetchDescriptor<PairedDevice>(
    fetchLimit: 10,
    fetchOffset: 20
)
```

---

## Relationships

### One-to-Many

```swift
@Model
final class Playlist {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \Song.playlist)
    var songs: [Song] = []
}

@Model
final class Song {
    var name: String
    var playlist: Playlist?
}
```

**Delete rules:**
- `.cascade` - Delete related items
- `.nullify` - Set relationship to nil
- `.deny` - Prevent deletion if related items exist
- `.noAction` - Do nothing

---

## Migrations

### Schema Versions

**File:** `Core/Models/SchemaVersions.swift`

```swift
enum HealthSyncSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [SyncConfiguration.self, PairedDevice.self, AuditEventRecord.self]
    }

    static var schema: Schema {
        Schema(versionIdentifier)
    }
}
```

### Migration Plan

```swift
enum HealthSyncMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [HealthSyncSchema.self]
    }

    static var stages: [MigrationStage] {
        []
    }

    static var migrationPlan: some SchemaMigrationPlan {
        HealthSyncMigrationPlan.self
    }
}
```

---

## Best Practices

### Soft Deletes

**Never hard delete important data:**

```swift
// ❌ WRONG: Hard delete
modelContext.delete(device)

// ✅ RIGHT: Soft delete
device.isActive = false
device.deletedAt = Date()
try? modelContext.save()
```

**Why:**
- Audit trail preserved
- Can recover if needed
- Better for debugging

### Default Values

```swift
@Model
final class SyncConfiguration {
    var enabledTypesCSV: String = HealthDataType.allCases
        .map(\.rawValue)
        .joined(separator: ",")  // ✅ Good default

    var createdAt: Date = Date()  // ✅ Good default
}
```

### Computed Properties for Convenience

```swift
@Model
final class SyncConfiguration {
    var enabledTypesCSV: String

    var enabledTypes: [HealthDataType] {
        get { /* parse */ }
        set { /* serialize */ }
    }
}
```

---

## Exercises

### 🟢 Beginner: Create a Model

**Task:** Create a SwiftData model for a health goal:

```swift
@Model
final class HealthGoal {
    // Add properties:
    // - name (String)
    // - target (Double)
    // - current (Double)
    // - unit (String)
    // - createdAt (Date)
}
```

---

### 🟡 Intermediate: Query with Predicate

**Task:** Fetch all active paired devices created in the last 30 days:

```swift
let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
let descriptor = FetchDescriptor<PairedDevice>(
    predicate: // Your code here
)
let devices = try context.fetch(descriptor)
```

---

### 🔴 Advanced: Relationship Modeling

**Task:** Model a health data sync log:

```swift
@Model
final class SyncSession {
    var startedAt: Date
    var endedAt: Date?
    var itemCount: Int

    // Add relationship to SyncLogEntry
    // Each session has multiple entries
}

@Model
final class SyncLogEntry {
    var dataType: String
    var count: Int

    // Add inverse relationship
}
```

---

## Common Pitfalls

### Pitfall 1: Forgetting to save

```swift
// WRONG: Modify but don't save
device.isActive = false
// Changes lost if app closes!

// RIGHT: Save after modifying
device.isActive = false
try? modelContext.save()
```

### Pitfall 2: Main thread violations

```swift
// WRONG: Fetch on background thread
Task {
    let devices = try context.fetch(...)  // Crash!
}

// RIGHT: Fetch on main thread
let devices = try modelContext.mainContext.fetch(...)

// Or use background context
let context = ModelContext(modelContainer)
await context.perform {
    let devices = try context.fetch(...)
}
```

### Pitfall 3: Not using @Model

```swift
// WRONG: Regular class
final class MyData {
    var name: String
}

// RIGHT: @Model macro
@Model
final class MyData {
    var name: String
}
```

---

## Key Takeaways

### ✅ SwiftData Patterns

| Pattern | Description |
|---------|-------------|
| `@Model` | Marks persistent class |
| `ModelContainer` | Holds database connection |
| `ModelContext` | Performs operations |
| `@Query` | Automatic view updates |
| `FetchDescriptor` | Query configuration |
| `#Predicate` | Type-safe filters |

---

## Coming Next

In **Chapter 6: Working with HealthKit**, you'll learn:

- HealthKit authorization
- Querying health data
- Data types and units
- Privacy considerations

---

**Next Chapter:** [Working with HealthKit](06-healthkit.md) →
