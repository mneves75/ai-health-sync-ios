# Chapter 4: Building User Interfaces with SwiftUI

**Declarative UI for Modern iOS Apps**

---

## Learning Objectives

After this chapter, you will be able to:

- ✅ Understand declarative vs. imperative UI
- ✅ Use SwiftUI views and modifiers
- ✅ Manage state with @Observable
- ✅ Compose complex layouts
- ✅ Handle user input

---

## The Simple Explanation

### What Is Declarative UI?

**Declarative** means describing **what** you want, not **how** to build it.

**Imperative (Old - UIKit):**
```swift
// Tell iOS EXACTLY how to build the UI
let button = UIButton()
button.setTitle("Click me", for: .normal)
button.backgroundColor = .blue
button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
view.addSubview(button)

button.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    button.topAnchor.constraint(equalTo: view.topAnchor, constant: 100)
])
```

**Declarative (New - SwiftUI):**
```swift
// Describe what you want
Button("Click me") {
    handleTap()
}
.buttonStyle(.borderedProminent)
```

**Think of it like:**
- **Imperative** = Giving driving directions ("Turn left, go 100m, turn right")
- **Declarative** = Entering a destination ("Navigate to 123 Main St")

### Why Declarative?

| Imperative | Declarative |
|------------|-------------|
| How to build | What to show |
| Bug-prone | Less bugs |
| Lots of code | Concise |
| Manual updates | Automatic |
| Hard to preview | Live previews |

---

## SwiftUI Basics

### View Protocol

All views conform to `View` protocol:

```swift
protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Self.Body { get }
}
```

**Simplest view:**

```swift
struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
```

**What's happening:**
1. `struct` = Value type (efficient)
2. `View` protocol = It's a view
3. `body` = Describes the view's content
4. `some View` = Opaque return type (performance)

### View Modifiers

**Modifiers** change how a view looks/behaves:

```swift
Text("Hello")
    .font(.largeTitle)           // Change font
    .foregroundColor(.blue)      // Change color
    .padding()                   // Add padding
    .background(Color.yellow)    // Add background
```

**Chained modifiers** (applied in order):

```swift
Text("Hello")
    .padding()          // Add padding around text
    .background(.blue)  // Blue background around padding
```

vs

```swift
Text("Hello")
    .background(.blue)  // Blue background just around text
    .padding()          // Padding around the blue background
```

---

## State Management

### @Observable (Swift 6)

Our app uses `@Observable` for state:

```swift
// File: App/AppState.swift:13
@MainActor
@Observable
final class AppState {
    var isServerRunning: Bool = false
    var serverPort: Int = 0
}
```

**Using it in a view:**

```swift
struct ContentView: View {
    @Environment(\.appState) private var appState

    var body: some View {
        VStack {
            if appState.isServerRunning {
                Text("Server running on port \(appState.serverPort)")
            } else {
                Text("Server stopped")
            }
        }
    }
}
```

**What happens:**
1. `@Environment` injects AppState
2. View observes `isServerRunning` and `serverPort`
3. When they change, view automatically updates
4. No manual notification needed

### Local State with @State

For view-local state, use `@State`:

```swift
struct ToggleView: View {
    @State private var isOn = false

    var body: some View {
        Toggle("Enable", isOn: $isOn)
    }
}
```

**`$isOn`** = Binding (two-way connection)

### Binding: Two-Way Connection

**Binding** lets child views modify parent state:

```swift
struct ParentView: View {
    @State private var isEnabled = true

    var body: some View {
        ChildView(isEnabled: $isEnabled)  // Pass binding
    }
}

struct ChildView: View {
    @Binding var isEnabled: Bool  // Accept binding

    var body: some View {
        Toggle("Enable", isOn: $isEnabled)  // Modifies parent's state
    }
}
```

**Flow:**
```
Parent @State
    ↓ $binding
Child @Binding
    ↓ Toggle modifies
Parent @State updates
    ↓ View refreshes
UI updates
```

---

## Common SwiftUI Views

### Text and Images

```swift
VStack {
    Text("Hello")
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(.primary)

    Image(systemName: "heart.fill")
        .font(.largeTitle)
        .foregroundColor(.red)
}
```

### Buttons

```swift
Button(action: {
    // Action when tapped
}) {
    Text("Click Me")
    Image(systemName: "hand.tap")
}
.buttonStyle(.borderedProminent)
```

### Toggle

```swift
Toggle("Enable Sync", isOn: $appState.isServerRunning)
```

### Lists

```swift
List {
    ForEach(HealthDataType.allCases) { type in
        HStack {
            Text(type.displayName)
            Spacer()
            if appState.isTypeEnabled(type) {
                Image(systemName: "checkmark")
            }
        }
    }
}
```

### Forms

```swift
Form {
    Section("Data Types") {
        ForEach(HealthDataType.allCases) { type in
            Toggle(type.displayName, isOn: bindingFor(type))
        }
    }

    Section("Server") {
        HStack {
            Text("Status")
            Spacer()
            Text(appState.isServerRunning ? "Running" : "Stopped")
        }
    }
}
```

---

## In Our Code: ContentView

**File:** `Features/ContentView.swift`

```swift
struct ContentView: View {
    @Environment(\.appState) private var appState

    var body: some View {
        NavigationStack {
            Form {
                // Server section
                serverSection

                // Health data types section
                dataTypesSection

                // Actions section
                actionsSection
            }
            .navigationTitle("Health Sync")
        }
    }
}
```

**Breaking it down:**

### Server Section

```swift
@ViewBuilder
private var serverSection: some View {
    Section("Server") {
        HStack {
            Text("Status")
            Spacer()
            Text(serverStatusText)
                .foregroundColor(serverStatusColor)
        }

        if appState.isServerRunning {
            HStack {
                Text("Port")
                Spacer()
                Text("\(appState.serverPort)")
                    .foregroundColor(.secondary)
            }

            if let fingerprint = appState.serverFingerprint, !fingerprint.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fingerprint")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(fingerprint)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
    }
}
```

**What's `@ViewBuilder`:**
- Function builder for views
- Allows conditional view creation
- Like `var body` but for computed properties

### Data Types Section

```swift
@ViewBuilder
private var dataTypesSection: some View {
    Section("Health Data Types") {
        ForEach(HealthDataType.allCases) { type in
            Toggle(type.displayName, isOn: bindingFor(type))
        }
    } header: {
        Text("Select which data types to share")
    } footer: {
        Text("Changes require restarting the server")
            .font(.caption)
    }
}
```

**Custom binding helper:**

```swift
private func bindingFor(_ type: HealthDataType) -> Binding<Bool> {
    Binding(
        get: { appState.syncConfiguration.enabledTypes.contains(type) },
        set: { enabled in
            appState.toggleType(type, enabled: enabled)
        }
    )
}
```

**Why custom binding:**
- Converts `enabledTypes` array to individual Bool bindings
- Toggle needs `Binding<Bool>`, not array check
- Clean separation of concerns

### Actions Section

```swift
@ViewBuilder
private var actionsSection: some View {
    Section("Actions") {
        if appState.isServerRunning {
            Button(action: {
                Task { await appState.stopServer() }
            }) {
                HStack {
                    Image(systemName: "stop.circle.fill")
                    Text("Stop Sharing")
                }
                .foregroundColor(.red)
            }

            Button(action: {
                Task { await appState.refreshPairingCode() }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh QR Code")
                }
            }

            Button(action: {
                Task { await appState.revokeAllPairings() }
            }) {
                HStack {
                    Image(systemName: "person.badge.minus")
                    Text("Revoke All Pairings")
                }
            }
            .foregroundColor(.orange)
        } else {
            Button(action: {
                Task { await appState.startServer() }
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Start Sharing")
                }
                .foregroundColor(.green)
            }
        }
    }
}
```

**Async button actions:**

```swift
Button(action: {
    Task { await appState.startServer() }
}) {
    Text("Start Sharing")
}
```

**Why `Task`:**
- Button actions are synchronous
- `startServer()` is async
- `Task` creates async context
- `await` waits for completion

---

## Layout System

### VStack, HStack, ZStack

```swift
VStack(spacing: 20) {        // Vertical stack
    Text("Title")
    HStack(spacing: 10) {    // Horizontal stack
        Text("Left")
        Text("Right")
    }
    ZStack {                 // Z-axis stack (layering)
        Circle()
            .fill(.blue)
        Text("Overlay")
    }
}
```

### Spacer

`Spacer` takes up available space:

```swift
HStack {
    Text("Left")
    Spacer()  // Pushes to edges
    Text("Right")
}
```

### Alignment and Spacing

```swift
VStack(alignment: .leading, spacing: 16) {
    Text("Title")
    Text("Subtitle")
}

HStack(spacing: 8) {
    ForEach(0..<5) { _ in
        Circle()
            .frame(width: 10, height: 10)
    }
}
```

---

## Conditional Views

### if-else

```swift
if appState.isServerRunning {
    RunningView()
} else {
    StoppedView()
}
```

### switch

```swift
switch appState.healthAuthorizationStatus {
case true:
    Image(systemName: "checkmark.circle.fill")
        .foregroundColor(.green)
case false:
    Image(systemName: "xmark.circle.fill")
        .foregroundColor(.red)
}
```

### Optional with if-let

```swift
if let error = appState.lastError {
    Text(error)
        .foregroundColor(.red)
}
```

---

## QR Code View

**File:** `Features/QRCodeView.swift`

```swift
struct QRCodeView: View {
    let qrCode: PairingQRCode

    var body: some View {
        VStack(spacing: 20) {
            Text("Scan to Pair")
                .font(.title)
                .fontWeight(.bold)

            if let image = generateQRCode() {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
            }

            VStack(spacing: 8) {
                QRCodeRow(label: "Host", value: qrCode.host)
                QRCodeRow(label: "Port", value: "\(qrCode.port)")
                QRCodeRow(label: "Fingerprint", value: qrCode.fingerprint)
            }
            .font(.system(.caption, design: .monospaced))
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
    }
}
```

**Key SwiftUI patterns:**
1. `if let` for optionals
2. `Image(uiImage:)` for UIKit interop
3. Modifiers chained in logical order
4. Composed small views

---

## Alert and Sheets

### Alert

```swift
.alert("Error", isPresented: $showError, presenting: error) { _ in
    Button("OK", role: .cancel) { }
} message: { error in
    Text(error.localizedDescription)
}
```

### Sheet

```swift`
.sheet(isPresented: $showingQRCode) {
    QRCodeView(qrCode: appState.pairingQRCode!)
}
```

---

## Exercises

### 🟢 Beginner: Create a Simple View

**Task:** Create a view that shows:
- A title "Health Sync"
- A button "Connect"
- A status label

```swift
struct SimpleView: View {
    @State private var isConnected = false

    var body: some View {
        // Your code here
    }
}
```

---

### 🟡 Intermediate: Create a Data Type List

**Task:** Create a list of all health data types with toggles:

```swift
struct DataTypesListView: View {
    @State private var enabledTypes: Set<HealthDataType> = []

    var body: some View {
        // Your code here
    }
}
```

---

### 🔴 Advanced: Create a Server Status View

**Task:** Create a view that shows:
- Server status (running/stopped)
- Port number (if running)
- Uptime (if running)
- Start/Stop button
- Color-coded status indicator

Use computed properties and custom bindings.

---

## Common Pitfalls

### Pitfall 1: Modifying state during view rendering

```swift
// WRONG: Modifying state in body
var body: some View {
    Text("Count: \(count)")
    count += 1  // ❌ Don't do this!
}

// RIGHT: Use .onAppear
var body: some View {
    Text("Count: \(count)")
        .onAppear {
            count += 1
        }
}
```

### Pitfall 2: Forgetting @State or @Binding

```swift
// WRONG: Trying to modify let or immutable value
struct ChildView: View {
    var isEnabled: Bool  // ❌ Can't modify!

    var body: some View {
        Toggle("Enable", isOn: $isEnabled)  // Error!
    }
}

// RIGHT: Use @Binding
struct ChildView: View {
    @Binding var isEnabled: Bool

    var body: some View {
        Toggle("Enable", isOn: $isEnabled)
    }
}
```

### Pitfall 3: Complex body causing rebuilds

```swift
// WRONG: Too much in body
var body: some View {
    // 500 lines of view code
    // Rebuilds entirely on any change
}

// RIGHT: Extract to subviews
var body: some View {
    VStack {
        ServerSection()
        DataTypesSection()
        ActionsSection()
    }
}
```

---

## Key Takeaways

### ✅ SwiftUI Patterns

| Pattern | Description | Example |
|---------|-------------|---------|
| `@Observable` | State management | `@Observable class AppState` |
| `@State` | Local state | `@State var text = ""` |
| `@Binding` | Two-way connection | `@Binding var isOn: Bool` |
| `@ViewBuilder` | Conditional views | `@ViewBuilder var section: some View` |
| `Task` | Async actions | `Task { await start() }` |

---

## Coming Next

In **Chapter 5: Persisting Data with SwiftData**, you'll learn:

- SwiftData models
- Querying data
- Relationships
- Migrations

---

**Next Chapter:** [Persisting Data with SwiftData](05-swiftdata.md) →
