# Study Guide & Spaced Repetition Tracker

**Your Complete Learning Companion**

---

## How to Use This Study Guide

This guide is designed to help you **master** the iOS Health Sync codebase, not just passively read about it.

### Daily Study Routine (60-90 minutes)

```
1. Warm-up (5 min)
   └─ Review previous day's flashcards

2. Read Chapter (20-30 min)
   └─ Stop at each 🧠 checkpoint to actively recall

3. Active Recall (10 min)
   └─ Complete all Stop & Think questions

4. Practice (20-30 min)
   └─ Do exercises, starting with 🟢

5. Teach-Back (10 min)
   └─ Explain concepts aloud in simple terms

6. Review (5 min)
   └─ Check understanding with Quick Reference
```

---

## Week-by-Week Learning Plan

### Week 1: Foundation

**Goal:** Understand what the app does and how it's organized

| Day | Chapter | Focus | Exercises |
|-----|---------|-------|-----------|
| 1 | Ch 0-1 | Learning framework + app overview | 🟢 Beginner |
| 2 | Ch 2 | Architecture (clean code, layers) | 🟢 Beginner |
| 3 | Ch 3 | Swift 6 concurrency (complex!) | 🟢 Beginner |
| 4 | Ch 3 | Continue Swift 6, practice more | 🟡 Intermediate |
| 5 | Review | Review all chapters, do exercises | 🔴 Advanced |

**Week 1 Goals:**
- [ ] Explain the app's purpose simply
- [ ] Draw the architecture from memory
- [ ] Understand async/await basics
- [ ] Know what actors are and why we use them

**Checkpoint:** Can you explain the app's architecture to a non-technical person?

---

### Week 2: User Interface & Data

**Goal:** Learn how the app displays and stores data

| Day | Chapter | Focus | Exercises |
|-----|---------|-------|-----------|
| 1 | Ch 4 | SwiftUI (declarative UI) | 🟢 Beginner |
| 2 | Ch 4 | Continue SwiftUI, build UI | 🟡 Intermediate |
| 3 | Ch 5 | SwiftData (persistence) | 🟢 Beginner |
| 4 | Practice | Build a small UI example | 🔴 Advanced |
| 5 | Review | Week 2 quiz, review gaps | All exercises |

**Week 2 Goals:**
- [ ] Create a basic SwiftUI view
- [ ] Understand @Observable state management
- [ ] Know how SwiftData persists data
- [ ] Understand soft deletion

**Checkpoint:** Can you create a SwiftUI view that uses SwiftData?

---

### Week 3: Core Features

**Goal:** Master HealthKit and Security

| Day | Chapter | Focus | Exercises |
|-----|---------|-------|-----------|
| 1-2 | Ch 6 | HealthKit (complex, take time) | 🟢 Beginner |
| 3 | Ch 6 | HealthKit authorization | 🟡 Intermediate |
| 4-5 | Ch 7 | Security (also complex) | 🟢 Beginner |

**Week 3 Goals:**
- [ ] Understand HealthKit's privacy model
- [ ] Know how to request authorization
- [ ] Understand Keychain storage
- [ ] Explain mTLS authentication

**Checkpoint:** Can you explain the security flow to someone?

---

### Week 4: Advanced Topics

**Goal:** Learn networking, CLI, and testing

| Day | Chapter | Focus | Exercises |
|-----|---------|-------|-----------|
| 1-2 | Ch 8 | Networking (HTTP server) | 🟢 Beginner |
| 3 | Ch 9 | CLI companion | 🟢 Beginner |
| 4 | Ch 10 | Testing patterns | 🟢 Beginner |
| 5 | Final | Comprehensive quiz, build something | 🔴 Advanced |

**Week 4 Goals:**
- [ ] Understand the HTTP server implementation
- [ ] Use the CLI tool
- [ ] Write basic tests
- [ ] Complete all chapter exercises

**Checkpoint:** Can you add a new feature to the app?

---

## Chapter-by-Chapter Study Guides

### Chapter 0: Learning Framework

**Key Concepts:**
- Active Learning Framework
- Feynman Technique
- Spaced Repetition
- Dual Coding

**Must-Know:**
1. The 5 steps: Read → Active Recall → Practice → Teach Back → Apply
2. Feynman Technique: Explain simply to identify gaps
3. Spaced Repetition: Review at increasing intervals
4. Dual Coding: Text + visuals = 89% better retention

**Common Mistakes:**
- ❌ Passive reading (no active recall)
- ❌ Cramming (no spaced repetition)
- ❌ Skipping exercises (no practice)
- ❌ Not teaching back (no Feynman)

**Quick Review Questions:**
1. What are the 5 steps of active learning?
2. How does the Feynman Technique work?
3. Why is spaced repetition effective?
4. What is dual coding?

---

### Chapter 1: What This App Does

**Key Concepts:**
- Local-first health data sync
- Peer-to-peer communication
- mTLS authentication
- QR code pairing
- Bonjour discovery

**Must-Know:**
1. Problem: Cloud health apps lack privacy
2. Solution: Direct device-to-device sync
3. Data types: Steps, Heart Rate, Sleep, Workouts
4. Security: mTLS with certificate exchange
5. Discovery: Bonjour on local network

**Code References:**
- `App/AppState.swift` - Main coordinator
- `Services/Network/NetworkServer.swift` - HTTP server
- `Services/Security/PairingService.swift` - Pairing logic

**Quick Review Questions:**
1. Why not use cloud storage?
2. How does pairing work?
3. What is mTLS?
4. What health data types are supported?

---

### Chapter 2: Architecture

**Key Concepts:**
- Layered Architecture
- Single Responsibility Principle
- Dependency Injection
- Protocol-Oriented Design
- Actor Isolation

**Must-Know:**
1. 4 Layers: Presentation → Application → Business → Data
2. Each layer has one responsibility
3. DI: Pass dependencies from outside
4. Protocols enable testing
5. Actors prevent data races

**Architecture Diagram (draw from memory):**
```
┌─────────────────┐
│   Presentation  │  SwiftUI Views
├─────────────────┤
│   Application   │  AppState (coordinator)
├─────────────────┤
│    Business     │  Services (actors)
├─────────────────┤
│      Data       │  HealthKit, SwiftData, etc.
└─────────────────┘
```

**Code References:**
- `App/AppState.swift:13` - Application layer
- `Services/HealthKit/HealthKitService.swift:12` - Business layer
- `Services/Network/NetworkServer.swift:11` - Business layer

**Quick Review Questions:**
1. What are the 4 layers?
2. Why use DI?
3. What does AppState do?
4. Why are services actors?

---

### Chapter 3: Swift 6 Concurrency

**Key Concepts:**
- async/await
- actors
- Sendable
- @Observable
- @MainActor

**Must-Know:**
1. async/await: Write async code linearly
2. actors: Thread-safe isolation (serialize access)
3. Sendable: Safe to share across actors
4. @Observable: Automatic state tracking
5. @MainActor: UI thread safety

**Comparison Table:**

| Old Way | New Way | Benefit |
|---------|---------|---------|
| Completion handlers | async/await | Linear code |
| ObservableObject | @Observable | Less boilerplate |
| DispatchQueue | @MainActor | Compiler-enforced |
| Locks | actors | No bugs |

**Code Patterns:**
```swift
// Async function
func fetch() async throws -> Data { ... }

// Actor for safety
actor Service {
    var data: Data?
}

// Sendable struct
struct DTO: Sendable { let id: UUID }

// Observable state
@Observable class AppState {
    var isRunning: Bool = false
}
```

**Quick Review Questions:**
1. What problem does async/await solve?
2. How do actors prevent data races?
3. What is Sendable?
4. When should you use @MainActor?

---

### Chapter 4: SwiftUI

**Key Concepts:**
- Declarative UI
- @Observable
- View Composition
- State Management

**Must-Know:**
1. Declarative: Describe **what**, not **how**
2. @Observable: Auto-track property changes
3. Views: Composable functions
4. State: Flows through environment

**Code Pattern:**
```swift
@Observable class AppState {
    var isServerRunning: Bool = false
}

struct ContentView: View {
    @Environment(\.appState) private var appState

    var body: some View {
        Text(appState.isServerRunning ? "Running" : "Stopped")
    }
}
```

**Quick Review Questions:**
1. What is declarative UI?
2. How do you access AppState?
3. What happens when @Observable property changes?
4. What is QRCodeView for?

---

### Chapter 5: SwiftData

**Key Concepts:**
- @Model macro
- ModelContainer
- Queries
- Soft Deletion

**Must-Know:**
1. @Model: Marks class for persistence
2. ModelContainer: Database connection
3. Queries: Fetch with predicates/sorts
4. Soft Delete: Mark deleted, don't remove

**Code Pattern:**
```swift
@Model
class SyncConfiguration {
    var enabledDataTypes: Set<HealthDataType>
    var deletedAt: Date?
}

// Query
@Query(filter: #Predicate { $0.deletedAt == nil })
private var configurations: [SyncConfiguration]
```

**Quick Review Questions:**
1. What is @Model?
2. How do you query SwiftData?
3. What is soft deletion?
4. Why is soft deletion important?

---

### Chapter 6: HealthKit

**Key Concepts:**
- Privacy-First Design
- Authorization
- HKSampleType
- HealthSampleMapper

**Must-Know:**
1. Privacy: User must grant permission
2. Authorization: Request per data type
3. Sample Types: HKQuantityType, HKCategoryType, HKWorkoutType
4. Mapper: Convert HKSample → DTO

**Authorization Flow:**
```
Request Authorization
    ↓
iOS Shows Permission Prompt
    ↓
User Grants/Denies
    ↓
App Can Read/Write Data
```

**Quick Review Questions:**
1. Why does HealthKit require authorization?
2. What is HKSampleType?
3. What does HealthSampleMapper do?
4. How do you request authorization?

---

### Chapter 7: Security

**Key Concepts:**
- Keychain Storage
- mTLS Authentication
- Pairing Tokens
- Audit Logging

**Must-Know:**
1. Keychain: Secure storage for secrets
2. mTLS: Mutual certificate authentication
3. Pairing: QR code → token exchange
4. Audit: Log all access for compliance

**Security Flow:**
```
Pairing:
iOS → Generate Certificate
iOS → Create QR Code with Token
Mac → Scan QR Code
Mac → Generate Certificate
Mac → Exchange Certificates
Both → Verify & Store
```

**Quick Review Questions:**
1. What is Keychain?
2. How does mTLS work?
3. What is a pairing token?
4. Why is audit logging important?

---

### Chapter 8: Networking

**Key Concepts:**
- Network Framework
- TLS 1.3
- Bonjour Discovery
- Rate Limiting

**Must-Know:**
1. Network Framework: HTTP server
2. TLS 1.3: Encrypts all traffic
3. Bonjour: Device discovery
4. Rate Limiting: Prevent abuse

**API Endpoints:**
| Endpoint | Method | Purpose |
|----------|--------|---------|
| /api/v1/status | GET | Server status |
| /api/v1/pairing | POST | Pair devices |
| /api/v1/health/data | POST | Fetch health data |
| /api/v1/health/types | GET | List data types |

**Quick Review Questions:**
1. What framework is used for the HTTP server?
2. How does Bonjour work?
3. What is rate limiting?
4. Why use TLS 1.3?

---

### Chapter 9: CLI Companion

**Key Concepts:**
- ArgumentParser
- Commands
- HTTP Client
- CSV Export

**Must-Know:**
1. ArgumentParser: Parse CLI arguments
2. Commands: discover, scan, pair, fetch, status, types, version
3. HTTP Client: Call iOS server
4. Export: Save as CSV/JSON

**Command Reference:**
| Command | Purpose |
|---------|---------|
| `discover` | Find iOS devices |
| `scan` | Read QR from clipboard |
| `pair` | Pair with iOS app |
| `fetch` | Fetch health data |
| `status` | Check connection |
| `types` | List enabled types |

**Quick Review Questions:**
1. What is ArgumentParser?
2. Which command finds devices?
3. How does the CLI fetch data?
4. What export formats are supported?

---

### Chapter 10: Testing

**Key Concepts:**
- Swift Testing
- Protocol Mocking
- AAA Pattern
- Code Coverage

**Must-Know:**
1. Swift Testing: @Test, #expect
2. Mocking: Fake implementations for testing
3. AAA: Arrange, Act, Assert
4. Coverage: Percentage tested

**Test Pattern:**
```swift
@Test("Service returns data")
func fetchReturnsData() async throws {
    // Arrange
    let mock = MockService()
    let sut = System(service: mock)

    // Act
    let result = await sut.fetch()

    // Assert
    #expect(result.count == 42)
}
```

**Quick Review Questions:**
1. What is Swift Testing?
2. What is protocol-based mocking?
3. What is the AAA pattern?
4. What is code coverage?

---

## Spaced Repetition Tracker

Track your reviews to cement knowledge in long-term memory.

### How to Use This Tracker

1. **After finishing a chapter**, mark "Complete" date
2. **Schedule reviews** at the intervals shown
3. **Check off reviews** as you complete them
4. **Adjust intervals** if you struggle (review more frequently)

### Chapter Tracking

| Chapter | Complete | Review 1<br/>(+1 day) | Review 2<br/>(+3 days) | Review 3<br/>(+1 week) | Review 4<br/>(+1 month) | Mastery |
|---------|----------|---------------------|----------------------|----------------------|----------------------|---------|
| Ch 0: Learning Framework | ____/____/____ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Ch 1: Overview | ____/____/____ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Ch 2: Architecture | ____/____/____ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Ch 3: Swift 6 | ____/____/____ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Ch 4: SwiftUI | ____/____/____ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Ch 5: SwiftData | ____/____/____ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Ch 6: HealthKit | ____/____/____ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Ch 7: Security | ____/____/____ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Ch 8: Networking | ____/____/____ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Ch 9: CLI | ____/____/____ | ☐ | ☐ | ☐ | ☐ | ☐ |
| Ch 10: Testing | ____/____/____ | ☐ | ☐ | ☐ | ☐ | ☐ |

**Mastery Criteria:** All 4 reviews complete + 90%+ on quiz

---

## Daily Review Checklist

Use this checklist every study session:

### Before Study (5 min)
- [ ] Review previous day's flashcards
- [ ] Check spaced repetition tracker for due reviews
- [ ] Set today's learning goal

### During Study (60-90 min)
- [ ] Read chapter section by section
- [ ] Stop at each 🧠 checkpoint
- [ ] Complete all ✅ Quick Checks
- [ ] Do exercises (at least 🟢)
- [ ] Take chapter quiz

### After Study (10 min)
- [ ] Teach-back: Explain concepts aloud
- [ ] Update spaced repetition tracker
- [ ] Mark flashcards as ✓ or ↻
- [ ] Schedule tomorrow's session

---

## Exam Preparation Guide

### 1 Week Before Exam

**Day 1-2: Review All Chapters**
- Read Quick Reference for each chapter
- Review all diagrams
- Do 1 exercise per chapter

**Day 3-4: Active Recall**
- Complete all flashcards
- Retake all chapter quizzes
- Teach-back each chapter

**Day 5-6: Practice**
- Do all 🟡 Intermediate exercises
- Attempt 1-2 🔴 Advanced exercises
- Build something small

**Day 7: Final Review**
- Comprehensive final quiz
- Review gaps only
- Light practice, don't cram

### Exam Day Checklist

**Before Exam:**
- [ ] Sleep well (no cramming!)
- [ ] Light breakfast
- [ ] Arrive early
- [ ] Relax (you've prepared!)

**During Exam:**
- [ ] Read questions carefully
- [ ] Answer easy questions first
- [ ] Use process of elimination
- [ ] Don't panic on hard questions
- [ ] Review if time permits

---

## Quick Reference: Key Concepts at a Glance

### Architecture
```
Presentation → Application → Business → Data
     ↓              ↓              ↓          ↓
   Views        AppState      Services   HealthKit
                                   ↓          ↓
                            SwiftData   Keychain
                                   ↓
                             Network
```

### Swift 6 Patterns
| Pattern | Purpose | Example |
|---------|---------|---------|
| async/await | Async code linearly | `await fetch()` |
| actor | Thread safety | `actor Service` |
| Sendable | Safe sharing | `struct DTO: Sendable` |
| @Observable | State tracking | `@Observable class State` |

### Data Flow
```
User Action → View → AppState → Service → Data
                              ↓                         ↓
                        State Update ← Return Data ← Query
                              ↓
                        Re-render
```

### Security Flow
```
Pairing: QR Code → Token Exchange → mTLS → Encrypted
Data: TLS 1.3 + Certificate Pinning
Audit: Log all HealthKit access
```

---

**Remember:** Learning is a journey, not a race. Take your time, understand deeply, and practice regularly. You've got this! 🚀

---

**Next Steps:**
1. Start with [Chapter 0: Welcome](00-welcome.md)
2. Use [Flashcards](FLASHCARDS.md) daily
3. Test yourself with [Quizzes](QUIZZES.md)
4. Track reviews in this guide
