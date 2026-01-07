# Video Transcript: Swift 6 Concurrency Deep Dive

**Video Title:** Understanding Swift 6 Concurrency - Async/Await and Actors
**Duration:** 25:00
**Difficulty:** Intermediate
**Related Docs:** [Chapter 3: Swift 6 Concurrency](../learn/03-swift6.md)

---

## Transcript

### [0:00] Introduction

**[Visual: Title slide with Swift logo and "Concurrency" text]**

**Speaker:** "Welcome to this deep dive into Swift 6 concurrency. I'm [Name], and today we're exploring how Swift 6's modern concurrency model makes it easier to write safe, performant code."

**[Visual: Split screen showing traditional threading vs Swift concurrency]**

**Speaker:** "Traditional concurrency with threads and locks is error-prone and difficult to get right. Swift 6 introduces async/await and actors that eliminate entire classes of bugs while making your code more readable."

**[Visual: iOS Health Sync app architecture diagram]**

**Speaker:** "We'll use examples from the iOS Health Sync app to see these concepts in action. Let's dive in!"

---

### [1:00] The Problem: Data Races

**[Visual: Two threads accessing shared memory simultaneously]**

**Speaker:** "First, let's understand the problem we're solving. A data race occurs when two threads access the same memory simultaneously, at least one writes, and there's no synchronization."

**[Visual: Code snippet showing unsafe shared state]**

```swift
// ❌ UNSAFE: Data race!
var counter = 0

DispatchQueue.global().async { counter += 1 }
DispatchQueue.global().async { counter += 1 }
// What's the value of counter? Nobody knows!
```

**Speaker:** "This code has a data race. Both threads read the counter, increment it, and write back. One write overwrites the other. The final value is unpredictable."

**[Visual: Bug report showing crashes from data races]**

**Speaker:** "Data races cause mysterious bugs that are hard to reproduce and fix. Swift 6's concurrency model prevents these at compile time."

---

### [2:30] Solution 1: Async/Await

**[Visual: Swift async/await syntax diagram]**

**Speaker:** "Swift 5.5 introduced async/await, a way to write asynchronous code that looks synchronous. Let's see how it works."

**[Visual: Code example showing async function]**

```swift
func fetchUserData() async -> String {
    // Simulate network request
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    return "John Doe"
}
```

**Speaker:** "The `async` keyword marks a function that can suspend. The `await` keyword marks suspension points where execution might pause."

**[Visual: Diagram showing execution flow with await]**

**Speaker:** "When you `await` something, the function suspends and releases the thread. Other work can run on that thread. When the awaited operation completes, execution resumes."

**[Visual: Calling async from sync context]**

```swift
Task {
    let name = await fetchUserData()
    print(name)
}
```

**Speaker:** "To call async code from sync code, wrap it in a Task. Task creates a new asynchronous context."

---

### [4:00] Error Handling with Async

**[Visual: Throwing async function example]**

**Speaker:** "Async functions can also throw errors. Combine `async` and `throws` in the signature:"

```swift
enum NetworkError: Error {
    case invalidURL
    case serverError
}

func fetchHealthData() async throws -> [String] {
    try await Task.sleep(nanoseconds: 1_000_000_000)

    if Bool.random() {
        throw NetworkError.serverError
    }

    return ["Steps: 10,000", "Heart Rate: 72 bpm"]
}
```

**Speaker:** "Call throwing async functions with `try await`:"

```swift
Task {
    do {
        let data = try await fetchHealthData()
        print(data)
    } catch NetworkError.serverError {
        print("Server error occurred")
    } catch {
        print("Unknown error: \(error)")
    }
}
```

---

### [6:00] Structured Concurrency

**[Visual: TaskGroup diagram showing parallel tasks]**

**Speaker:** "Swift provides structured concurrency with TaskGroups. Run multiple async tasks concurrently and collect their results:"

```swift
func fetchMultipleSources() async -> [String] {
    return await withTaskGroup(of: String.self) { group in
        group.addTask { return "HealthKit data" }
        group.addTask { return "Activity data" }
        group.addTask { return "Location data" }

        var results: [String] = []
        for await result in group {
            results.append(result)
        }
        return results
    }
}
```

**Speaker:** "Tasks added to the group run concurrently. The `for await` loop collects results as they complete."

**[Visual: Timeline showing parallel execution]**

**Speaker:** "If each task takes 1 second, three tasks complete in roughly 1 second total, not 3 seconds. That's the power of concurrent execution."

---

### [8:00] Solution 2: Actors

**[Visual: Actor concept diagram]**

**Speaker:** "Now let's talk about actors. Actors eliminate data races by ensuring only one task can access their state at a time."

**[Visual: Basic actor example]**

```swift
actor BasicCounter {
    private var count = 0

    func increment() -> Int {
        count += 1  // Safe!
        return count
    }
}
```

**Speaker:** "The `actor` keyword makes this a data race-safe type. All properties and methods are isolated to the actor. Only one task can execute actor code at a time."

**[Visual: Timeline showing serialized access to actor]**

**Speaker:** "If ten tasks call `increment()` simultaneously, they execute one at a time. The actor serializes access, preventing data races."

---

### [10:00] Using Actors

**[Visual: Creating and using actor instance]**

```swift
let counter = BasicCounter()

await withTaskGroup(of: Void.self) { group in
    for _ in 1...10 {
        group.addTask {
            let value = await counter.increment()
            print(value)
        }
    }
}
```

**Speaker:** "Notice the `await` when calling actor methods. It suspends until the actor is available."

**[Visual: Diagram showing tasks queueing for actor access]**

**Speaker:** "Tasks queue up for access to the actor. Each task gets exclusive access when it's its turn. This prevents concurrent access."

---

### [11:30] Real-World Example: HealthDataManager

**[Visual: HealthDataManager actor code]**

**Speaker:** "Let's look at a real example from the iOS Health Sync app:"

```swift
struct HealthSample {
    let id: UUID
    let type: String
    let value: Double
    let timestamp: Date
}

actor HealthDataManager {
    private var samples: [UUID: HealthSample] = [:]

    func addSample(_ sample: HealthSample) {
        samples[sample.id] = sample
    }

    func getSamplesByType(_ type: String) -> [HealthSample] {
        return samples.values.filter { $0.type == type }
    }
}
```

**Speaker:** "This actor manages health data. Multiple parts of the app can add samples concurrently without data races."

**[Visual: App architecture showing HealthDataManager]**

**Speaker:** "The iOS app uses actors like this for HealthKitService, NetworkServer, and other shared services. Thread safety is guaranteed by the type system."

---

### [13:00] Actor Isolation Explained

**[Visual: Actor isolation diagram]**

**Speaker:** "Swift's actor isolation model ensures safety. Let's understand how it works:"

**[Visual: Code showing isolated vs non-isolated code]**

```swift
actor DataStore {
    private var data: [String] = []

    // Isolated: only runs inside actor
    func add(item: String) {
        data.append(item)
    }

    // Non-isolated: can run outside actor
    nonisolated func getHelp() -> String {
        return "Call add(item:) to add data"
    }
}
```

**Speaker:** "Mark methods as `nonisolated` if they don't access actor-isolated state. These can be called without `await`."

---

### [14:30] MainActor for UI Updates

**[Visual: MainActor and UI diagram]**

**Speaker:** "SwiftUI UI updates must happen on the main actor. Swift provides the @MainActor attribute for this:"

```swift
@MainActor
class ContentViewModel: Observable {
    @Published var steps: Int = 0

    func updateSteps() {
        // Runs on main actor
        steps = 10000
    }
}
```

**Speaker:** "Properties and methods marked with @MainActor run on the main thread. SwiftUI views are implicitly @MainActor."

**[Visual: UI update flow diagram]**

**Speaker:** "When you need to update the UI from a background task:"

```swift
Task {
    // Background work
    let data = await fetchFromNetwork()

    // UI update on main actor
    await MainActor.run {
        viewModel.steps = data.count
    }
}
```

---

### [16:00] Sendable Protocol

**[Visual: Sendable protocol diagram]**

**Speaker:** "Swift 6 enforces Sendable for data passed between concurrent contexts. Sendable types are safe to share across concurrency boundaries."

**[Visual: Sendable types examples]**

```swift
// Value types are Sendable
struct Point: Sendable {
    let x: Double
    let y: Double
}

// Actors are Sendable
actor DataStore: Sendable {
    // ...
}

// Immutable classes can be Sendable
final class ImmutableData: @unchecked Sendable {
    let value: String
}
```

**[Visual: Non-Sendable warning]**

```swift
// ❌ Not Sendable
class MutableData {
    var value: String
}

// Swift won't let you share this across actors
```

---

### [17:30] Common Patterns

**[Visual: Pattern: Async Property]**

**Speaker:** "Here are some common patterns. First, async computed properties:"

```swift
actor SettingsStore {
    private var settings: [String: Any]?

    var settingsLoaded: Bool {
        settings != nil
    }

    func loadSettings() async throws {
        settings = try await fetchSettings()
    }
}
```

**[Visual: Pattern: Async Sequence]**

**Speaker:** "Async sequences for streaming data:"

```swift
for await sample in healthSampleStream {
    print("Received: \(sample)")
}
```

**[Visual: Pattern: Task Cancellation]**

**Speaker:** "Cooperative task cancellation:"

```swift
Task {
    for await sample in healthSampleStream {
        try Task.checkCancellation()
        process(sample)
    }
}

// Later
task.cancel()
```

---

### [19:00] Debugging Concurrency

**[Visual: Swift Concurrency Runtime debugging tools]**

**Speaker:** "Debugging concurrent code can be tricky. Use these tools:"

**[Visual: Xcode concurrency debugger]**

**Speaker:** "Xcode's concurrency debugger shows task relationships and suspension points. Use the Thread Sanitizer to detect data races:"

**[Visual: Build settings showing Thread Sanitizer]**

**Speaker:** "Enable Thread Sanitizer in your build settings. It catches data races at runtime by adding instrumentation."

**[Visual: Swift 6 concurrency warnings]**

**Speaker:** "Swift 6 emits warnings for potential concurrency issues. Pay attention to these warnings - they often indicate real bugs."

---

### [20:30] Performance Considerations

**[Visual: Performance comparison chart]**

**Speaker:** "Actors add a small synchronization overhead. Is it worth it?"

**[Visual: Benchmark results]**

**Speaker:** "In most cases, yes. The overhead is minimal compared to the cost of data races. Use actors for shared mutable state. Use value types (structs) for isolated data."

**[Visual: When to use actors decision tree]**

**Speaker:** "Use actors when: Data is mutable AND accessed from multiple tasks. Use value types when: Data is immutable OR only accessed from one task."

---

### [22:00] Best Practices

**[Visual: Best practices checklist]**

**Speaker:** "Let's review best practices:"

1. **Prefer async/await over callbacks**
   - More readable and easier to reason about

2. **Use actors for shared mutable state**
   - Eliminates data races at compile time

3. **Keep actors small and focused**
   - One responsibility per actor

4. **Mark non-isolated methods appropriately**
   - Avoids unnecessary `await`

5. **Handle errors properly**
   - Don't ignore throwing async functions

6. **Use structured concurrency**
   - TaskGroups for parallel work

7. **Test concurrent code thoroughly**
   - Use Thread Sanitizer

---

### [23:30] Conclusion

**[Visual: Summary diagram]**

**Speaker:** "To summarize: Swift 6's concurrency model provides:"

- ✅ Data race safety at compile time
- ✅ Readable asynchronous code
- ✅ Structured concurrency
- ✅ Automatic thread management

**[Visual: iOS Health Sync app architecture highlights]**

**Speaker:** "The iOS Health Sync app uses these patterns throughout: HealthKitService, NetworkServer, PairingService - all are actors providing thread-safe access to shared resources."

**[Visual: Learning path diagram]**

**Speaker:** "Continue learning with: Chapter 3 of the Learning Guide for more details, the code examples in the examples directory, and Apple's Swift concurrency documentation."

---

### [24:30] Next Steps

**[Visual: Recommended next videos]**

**Speaker:** "Thanks for watching! Next up: 'SwiftUI @Observation Framework' to learn about modern state management. See you there!"

**[End of video]**

---

## Additional Resources

- **[Chapter 3: Swift 6 Concurrency](../learn/03-swift6.md)** - Comprehensive guide
- **[Example: Async/Await](../../examples/swift/01-async-await.swift)** - Runnable code
- **[Example: Actors](../../examples/swift/02-actors.swift)** - Runnable code
- **[Apple: Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)** - Official docs

---

## Video Metadata

| Property | Value |
|----------|-------|
| **Title** | Swift 6 Concurrency Deep Dive |
| **Duration** | 25:00 |
| **Difficulty** | Intermediate |
| **Prerequisites** | Basic Swift knowledge |
| **Related Docs** | Chapter 3: Swift 6 Concurrency |
| **Tags** | swift6, concurrency, async, await, actors |
| **Language** | English |
| **Subtitles Available** | Yes (English) |
| **Recorded Date** | 2026-01-07 |
| **Last Updated** | 2026-01-07 |

---

## Code Examples Used

All code examples in this transcript are available as runnable files:

- `examples/swift/01-async-await.swift`
- `examples/swift/02-actors.swift`

---

**Transcript Version:** 1.0.0
**Last Updated:** 2026-01-07
