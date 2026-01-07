# Flashcards: iOS Health Sync Learning Guide

**Active Recall Practice for All Chapters**

---

## How to Use These Flashcards

1. **Cover the answer** and try to recall from memory
2. **Say it aloud** before checking
3. **If correct**, mark as known (✓)
4. **If wrong**, mark as review (↻)
5. **Review missed cards** tomorrow

> **Research:** Active recall is one of the most effective learning techniques — [Edumentors, 2025](https://edumentors.co.uk/blog/3-active-recall-techniques-everyone-should-know/)

---

## Chapter 0: Learning Framework

### Q: What are the 5 steps of the Active Learning Framework?
<details>
<summary>Click to see answer</summary>

**A:** Read → Active Recall → Practice → Teach Back → Apply
</details>

### Q: What is the Feynman Technique?
<details>
<summary>Click to see answer</summary>

**A:** A learning method where you explain concepts simply (as if to a 12-year-old) to identify gaps in your understanding, then review to fill those gaps.
</details>

### Q: What is dual coding and why is it effective?
<details>
<summary>Click to see answer</summary>

**A:** Combining text with visuals (diagrams). Research shows it improves retention by 89% compared to text alone.
</details>

### Q: What is spaced repetition?
<details>
<summary>Click to see answer</summary>

**A:** Reviewing material at increasing intervals (tomorrow, 3 days, 1 week, 1 month) to cement it in long-term memory.
</details>

---

## Chapter 1: What This App Does

### Q: What problem does the iOS Health Sync app solve?
<details>
<summary>Click to see answer</summary>

**A:** It allows secure, peer-to-peer syncing of Apple Health data from iPhone to macOS CLI without cloud intermediaries, giving users full control over their health data.
</details>

### Q: What are the 4 main health data types the app supports?
<details>
<summary>Click to see answer</summary>

**A:** Steps (HKQuantityType), Heart Rate (HKQuantityType), Sleep Analysis (HKCategoryType), Workouts (HKWorkoutType)
</details>

### Q: What is mTLS and why is it used?
<details>
<summary>Click to see answer</summary>

**A:** Mutual TLS - both client and server authenticate each other with certificates. Used for device-to-device security without passwords.
</details>

### Q: What is the pairing process?
<details>
<summary>Click to see answer</summary>

**A:** iOS app generates QR code with pairing token → macOS CLI scans QR → mutual certificate exchange → devices trust each other → encrypted communication established
</details>

### Q: Why doesn't the app use cloud storage?
<details>
<summary>Click to see answer</summary>

**A:** Privacy (health data stays on devices), security (no third-party access), control (user owns their data), compliance (GDPR/HIPAA friendly)
</details>

---

## Chapter 2: Architecture

### Q: What are the 4 layers of the app's architecture?
<details>
<summary>Click to see answer</summary>

**A:** Presentation (SwiftUI views) → Application (AppState coordinator) → Business (services) → Data (HealthKit, SwiftData, Keychain, Network)
</details>

### Q: What is the single responsibility principle?
<details>
<summary>Click to see answer</summary>

**A:** Each component should have one reason to change. In our app: views display, AppState coordinates, services handle business logic, frameworks manage data.
</details>

### Q: What is dependency injection?
<details>
<summary>Click to see answer</summary>

**A:** Passing dependencies from outside instead of creating them inside. Makes code testable, flexible, and loosely coupled.
</details>

### Q: What does AppState do?
<details>
<summary>Click to see answer</summary>

**A:** Coordinates all services, manages UI state, is the single source of truth for the app, runs on @MainActor for UI safety.
</details>

### Q: Why are all services actors?
<details>
<summary>Click to see answer</summary>

**A:** To prevent data races. Services hold mutable state and receive concurrent calls. Actors serialize access and ensure thread safety.
</details>

### Q: What is the benefit of protocol-oriented design?
<details>
<summary>Click to see answer</summary>

**A:** Enables testability (can create mocks), loose coupling (implementations can change), and clear contracts (protocols define behavior).
</details>

---

## Chapter 3: Swift 6 Concurrency

### Q: What is the difference between concurrency and parallelism?
<details>
<summary>Click to see answer</summary>

**A:** Concurrency is about structure (dealing with multiple things at once), parallelism is about execution (actually doing multiple things at once). You can have concurrent code that's not parallel.
</details>

### Q: What problem does async/await solve?
<details>
<summary>Click to see answer</summary>

**A:** Eliminates "callback hell" by allowing asynchronous code to be written linearly, like synchronous code, making it easier to read and maintain.
</details>

### Q: What is a data race?
<details>
<summary>Click to see answer</summary>

**A:** When two threads access shared data simultaneously without coordination, causing undefined behavior and corrupted state.
</details>

### Q: How do actors prevent data races?
<details>
<summary>Click to see answer</summary>

**A:** Actors serialize access - only one task can execute inside the actor at a time. Other tasks wait their turn, ensuring data consistency.
</details>

### Q: What does Sendable mean?
<details>
<summary>Click to see answer</summary>

**A:** Data that is safe to pass between concurrent contexts (actors). Sendable types are either immutable (value types copied when passed) or have thread-safe isolation (actors).
</details>

### Q: What does @Observable do?
<details>
<summary>Click to see answer</summary>

**A:** Automatically tracks property changes and notifies observers. Used in SwiftUI for state management without manual @Published wrappers.
</details>

### Q: What is @MainActor and when is it used?
<details>
<summary>Click to see answer</summary>

**A:** Ensures code runs on the main thread (UI thread). Used for UI updates and @Observable classes that drive SwiftUI views.
</details>

### Q: How do you bridge callback-based APIs to async/await?
<details>
<summary>Click to see answer</summary>

**A:** Use `withCheckedThrowingContinuation` to wrap the callback, then call `continuation.resume(returning:)` or `continuation.resume(throwing:)` to return the result.
</details>

---

## Chapter 4: SwiftUI

### Q: What is declarative UI?
<details>
<summary>Click to see answer</summary>

**A:** Describing **what** the UI should look like for a given state, rather than **how** to build it (imperative). SwiftUI recomputes the view when state changes.
</details>

### Q: What is @Observable?
<details>
<summary>Click to see answer</summary>

**A:** Swift 6 macro that automatically tracks property changes and notifies observers. Replaces ObservableObject + @Published.
</details>

### Q: How do you access AppState in SwiftUI views?
<details>
<summary>Click to see answer</summary>

**A:** Using the environment: `@Environment(\.appState) private var appState`
</details>

### Q: What is the purpose of QRCodeView?
<details>
<summary>Click to see answer</summary>

**A:** Displays the pairing QR code that macOS CLI scans to establish secure device-to-device connection.
</details>

---

## Chapter 5: SwiftData

### Q: What is SwiftData?
<details>
<summary>Click to see answer</summary>

**A:** Apple's modern persistence framework that uses Core Data under the hood with a simpler Swift API. Supports @Model macros, relationships, and queries.
</details>

### Q: What is @Model?
<details>
<summary>Click to see answer</summary>

**A:** A macro that marks a class as a SwiftData model, automatically generating schema and persistence code.
</details>

### Q: What is soft deletion and why is it important?
<details>
<summary>Click to see answer</summary>

**A:** Marking records as deleted with a `deletedAt` timestamp instead of actually removing them. Important for audit trails, data recovery, and analytics.
</details>

### Q: How do you query SwiftData?
<details>
<summary>Click to see answer</summary>

**A:** Using `@Query` macro in SwiftUI or `fetch()` with predicates and sort descriptors programmatically.
</details>

---

## Chapter 6: HealthKit

### Q: What is HealthKit?
<details>
<summary>Click to see answer</summary>

**A:** Apple's framework for accessing health data. Central repository for all health/fitness data on iOS, with privacy-first design.
</details>

### Q: Why does HealthKit require user authorization?
<details>
<summary>Click to see answer</summary>

**A:** Privacy. Health data is sensitive. Users must explicitly grant permission for each data type. iOS shows permission prompts on first access.
</details>

### Q: What is HKSampleType?
<details>
<summary>Click to see answer</summary>

**A:** Represents a type of health sample that can be stored in HealthKit. Examples: HKQuantityType (steps, heart rate), HKCategoryType (sleep), HKWorkoutType.
</details>

### Q: What is the HealthSampleMapper?
<details>
<summary>Click to see answer</summary>

**A:** A utility that converts HealthKit's native HKSample objects to our HealthSampleDTO format for network transfer.
</details>

---

## Chapter 7: Security

### Q: What is Keychain?
<details>
<summary>Click to see answer</summary>

**A:** iOS's secure storage for sensitive data (keys, passwords, certificates). Encrypted, protected by device passcode/biometrics.
</details>

### Q: What is mTLS authentication?
<details>
<summary>Click to see answer</summary>

**A:** Mutual TLS - both client and server present certificates to prove identity. More secure than passwords, no shared secrets.
</details>

### Q: What is a pairing token?
<details>
<summary>Click to see answer</summary>

**A:** A one-time token embedded in QR code for initial device pairing. Contains certificate fingerprint, expires after 5 minutes.
</details>

### Q: Why is audit logging important for health data?
<details>
<summary>Click to see answer</summary>

**A:** Compliance (GDPR requires audit trails), security (detect unauthorized access), debugging (trace data flow), accountability (who accessed what when).
</details>

---

## Chapter 8: Networking

### Q: What framework does the app use for networking?
<details>
<summary>Click to see answer</summary>

**A:** Network Framework (swift-nio) for the HTTP server, plus Bonjour for local network discovery.
</details>

### Q: What is TLS 1.3?
<details>
<summary>Click to see answer</summary>

**A:** The latest version of TLS, providing encrypted communication. Used for all network traffic in the app.
</details>

### Q: How does the macOS CLI discover iOS devices?
<details>
<summary>Click to see answer</summary>

**A:** Using Bonjour (zero-configuration networking). iOS app broadcasts service, macOS CLI discovers devices on local network.
</details>

### Q: What is rate limiting and why is it used?
<details>
<summary>Click to see answer</summary>

**A:** Limiting how many requests can be made in a time window (60 requests per minute in our app). Prevents abuse and ensures fair resource usage.
</details>

---

## Chapter 9: CLI Companion

### Q: What is ArgumentParser?
<details>
<summary>Click to see answer</summary>

**A:** Apple's Swift package for parsing command-line arguments. Automatically generates help text and validates inputs.
</details>

### Q: What CLI commands are available?
<details>
<summary>Click to see answer</summary>

**A:** `discover` (find devices), `scan` (read QR from clipboard), `pair` (pair with iOS), `fetch` (get health data), `status` (check connection), `types` (list enabled types), `version` (show version)
</details>

---

## Chapter 10: Testing

### Q: What is the Swift Testing framework?
<details>
<summary>Click to see answer</summary>

**A:** Apple's modern testing framework using `@Test` macros and `#expect` assertions, replacing XCTest.
</details>

### Q: What is protocol-based mocking?
<details>
<summary>Click to see answer</summary>

**A:** Creating fake implementations of protocols for testing. Allows testing code without dependencies (HealthKit, network, etc.).
</details>

### Q: What is the AAA pattern?
<details>
<summary>Click to see answer</summary>

**A:** Arrange (set up test data) → Act (call code being tested) → Assert (verify expected outcome)
</details>

### Q: What is code coverage?
<details>
<summary>Click to see answer</summary>

**A:** The percentage of code executed by tests. Helps identify untested code and potential bugs.
</details>

---

## Study Tips

### 🎯 Daily Practice
- **10 minutes** of flashcards beats **2 hours** of cramming
- Review missed cards immediately
- Space out reviews: same day, next day, 3 days, 1 week

### 🧠 Active Recall
- **Don't just read** - actively recall
- **Say answers aloud** before checking
- **Write down** what you remember
- **Explain to others** (Feynman Technique)

### 📊 Track Progress
- Mark cards as ✓ (known) or ↻ (review)
- Review ↻ cards more frequently
- Remove ✓ cards from daily rotation

---

**Remember:** The goal isn't to finish all flashcards. The goal is to remember what you learn. Quality over quantity!
