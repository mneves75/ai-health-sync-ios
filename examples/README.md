# Runnable Code Examples

**Learn by doing - experiment with working Swift code**

---

## Overview

This directory contains runnable Swift code examples that demonstrate key concepts from the iOS Health Sync app. Each example is self-contained and can be run independently with the Swift compiler.

## Prerequisites

- Swift 5.5+ (included with Xcode 13+)
- macOS 12+ or Linux with Swift installed
- No external dependencies required

---

## Available Examples

### 1. Async/Await Basics (`01-async-await.swift`)

**Learn:** Swift 6's modern concurrency model

**Topics covered:**
- Basic async/await syntax
- Error handling with throws
- Structured concurrency with TaskGroups
- Concurrent task execution

**Run it:**
```bash
cd examples/swift
swift 01-async-await.swift
```

**Time:** 5 minutes

---

### 2. Actors for Thread Safety (`02-actors.swift`)

**Learn:** Swift 6 actors for data race safety

**Topics covered:**
- Basic actor syntax
- Actor-isolated methods
- Thread-safe state management
- Real-world HealthDataManager example
- Bank account example (classic concurrency problem)

**Run it:**
```bash
swift 02-actors.swift
```

**Time:** 10 minutes

---

### 3. @Observation Framework (`03-observation.swift`)

**Learn:** SwiftUI's modern state management

**Topics covered:**
- @Observable macro (iOS 17+)
- Automatic change tracking
- Observable with async operations
- Manual change tracking
- Comparison with ObservableObject

**Run it:**
```bash
swift 03-observation.swift
```

**Time:** 8 minutes

---

### 4. Modern Networking (`04-networking.swift`)

**Learn:** URLSession with async/await

**Topics covered:**
- Generic fetch methods
- Error handling with custom errors
- Thread-safe NetworkManager actor
- Mock API simulation
- POST requests with JSON encoding

**Run it:**
```bash
swift 04-networking.swift
```

**Time:** 12 minutes

---

### 5. Combine Framework (`05-combine.swift`)

**Learn:** Reactive programming with Combine

**Topics covered:**
- Publishers and Subscribers
- PassthroughSubject vs CurrentValueSubject
- Debouncing user input
- Combining multiple publishers
- Network requests with Future
- Real-time data monitoring

**Run it:**
```bash
swift 05-combine.swift
```

**Time:** 15 minutes

---

### 6. Real HealthKit Service (`06-real-healthkit-service.swift`) ⭐

**Learn:** The ACTUAL HealthKitService from iOS Health Sync

**Topics covered:**
- Real actor-based service architecture
- Production async/await patterns
- HealthKit authorization handling (privacy-first)
- Memory management (10,000 sample cap)
- Pagination implementation
- Error handling in real-world code

**What makes this different:**
This is extracted directly from the iOS Health Sync app - not a generic example.

**Run it:**
```bash
swift 06-real-healthkit-service.swift
```

**Time:** 20 minutes

**Note:** Simplified version for clarity - see actual app source for full implementation

---

### 7. Real Network Server (`07-network-server.swift`) ⭐ NEW

**Learn:** The ACTUAL NetworkServer from iOS Health Sync

**Topics covered:**
- Actor-based TLS 1.3 server
- Mutual TLS (mTLS) authentication
- Rate limiting (sliding window algorithm)
- HTTP request routing and handling
- Security best practices (request size limits, timeouts)
- Structured logging with os.Logger

**What makes this different:**
Real production server code with comprehensive security patterns.

**Run it:**
```bash
swift 07-network-server.swift
```

**Time:** 25 minutes

**Note:** Shows patterns from actual NetworkServer.swift

---

### 8. Real Pairing Service (`08-pairing-service.swift`) ⭐ NEW

**Learn:** The ACTUAL PairingService from iOS Health Sync

**Topics covered:**
- Secure token generation and validation
- Constant-time comparison (timing attack prevention)
- SHA256 token hashing (never store tokens!)
- Privacy-first design (anonymized client names)
- Rate limiting for failed attempts
- SwiftData persistence

**What makes this different:**
Real security code with timing attack prevention and privacy features.

**Run it:**
```bash
swift 08-pairing-service.swift
```

**Time:** 20 minutes

**Note:** Shows patterns from actual PairingService.swift

---

### 9. Real Certificate Service (`09-certificate-service.swift`) ⭐ NEW

**Learn:** The ACTUAL CertificateService from iOS Health Sync

**Topics covered:**
- Keychain-based certificate storage
- Self-signed TLS certificate generation
- ECDSA P-256 private key creation
- Certificate fingerprint calculation
- Thread-safe identity creation
- Security framework integration

**What makes this different:**
Real cryptographic code for certificate management.

**Run it:**
```bash
swift 09-certificate-service.swift
```

**Time:** 15 minutes

**Note:** Shows patterns from actual CertificateService.swift

---

## How to Use These Examples

### ⚠️ Important Notes

**These examples are designed for LEARNING Swift patterns**, not necessarily as standalone runnable scripts. They demonstrate concepts from the iOS Health Sync app but may require adjustments to run standalone.

**Known Issues:**
- Examples use `@main` attribute which requires Swift 6+
- Some examples have top-level code that conflicts with direct execution
- Example 6 (Real HealthKitService) shows patterns but requires the full HealthKit framework

### Running the Examples

**Option 1: Typecheck only (recommended)**
```bash
cd examples/swift
swiftc -typecheck 01-async-await.swift
```

**Option 2: Run with Swift REPL**
```bash
cd examples/swift
swift
  import Foundation
  // Paste code from example
```

**Option 3: Copy into Xcode Playground**
1. Create new Playground in Xcode
2. Copy code from example
3. Run in Playground

**Option 4: Reference the actual app code**
- The real implementations are in: `iOS Health Sync App/iOS Health Sync App/Services/`
- Example 06 shows the structure but see the actual file for working code

### For Learning

1. **Read the code first** - Try to understand what it does
2. **Run it** - See the actual output
3. **Modify it** - Change values, add print statements
4. **Break it** - Introduce errors and see what happens
5. **Build on it** - Add your own features

### For Teaching

Each example includes:
- ✅ Clear comments explaining concepts
- ✅ Runnable main() function
- ✅ Expected output in comments
- ✅ Key takeaways summary

Use them as:
- Interactive demos
- Homework assignments
- Interview preparation
- Code review examples

---

## Common Patterns Demonstrated

### Error Handling

```swift
enum NetworkError: Error {
    case invalidURL
    case serverError
}

func fetchData() async throws -> Data {
    // Implementation
}

// Usage
do {
    let data = try await fetchData()
} catch NetworkError.serverError {
    print("Server error")
}
```

### Actor Safety

```swift
actor SafeCounter {
    private var count = 0

    func increment() -> Int {
        count += 1  // Thread-safe by default
        return count
    }
}
```

### Async Streams

```swift
await withTaskGroup(of: String.self) { group in
    group.addTask { return "Task 1" }
    group.addTask { return "Task 2" }

    for await result in group {
        print(result)
    }
}
```

---

## Extension Ideas

**Challenge yourself** by extending these examples:

### 1. Async/Await
- Add a timeout to async operations
- Implement retry logic
- Create a parallel image downloader

### 2. Actors
- Build a thread-safe cache
- Implement a rate limiter
- Create a concurrent data processor

### 3. @Observation
- Build a form with validation
- Create a multi-step wizard
- Implement undo/redo functionality

### 4. Networking
- Add request caching
- Implement pagination
- Handle offline mode
- Add request cancellation

### 5. Combine
- Build a search with autocomplete
- Create real-time charts
- Implement gesture recognition
- Build a reactive form

---

## Running on Different Platforms

### macOS (Recommended)

```bash
cd examples/swift
swift 01-async-await.swift
```

### Linux

```bash
swift 01-async-await.swift
```

**Note:** Combine requires macOS 10.15+. Example 5 may not work on Linux.

### Swift Playgrounds (Xcode)

1. Open Xcode
2. File → New → Playground
3. Copy example code into the playground
4. Click Run (▶️)

---

## Troubleshooting

### "command not found: swift"

**Solution:** Install Swift from [swift.org](https://swift.org/download/)

### "Permission denied"

**Solution:** Make files executable (optional but recommended)
```bash
chmod +x examples/swift/*.swift
```

### Combine errors on Linux

**Solution:** Combine is not available on Linux. Skip example 5 or use macOS.

### Version warnings

**Solution:** Some features require Swift 5.9+ for @Observable or Swift 5.5+ for async/await. Update Xcode or Swift toolchain.

---

## Related Documentation

- **[Async/Await in Swift](../learn/03-swift6.md#asyncawait)** - Deep dive into concurrency
- **[Actor Isolation](../learn/03-swift6.md#actors)** - Understanding data race safety
- **[SwiftUI State Management](../learn/04-swiftui.md)** - @Observation in views
- **[Network Architecture](../learn/08-networking.md)** - App's networking layer

---

## Contributing

Found a bug or want to add an example?

1. Follow the existing format
2. Include clear comments
3. Add expected output
4. Test on multiple Swift versions
5. Update this README

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

---

**Examples Version:** 1.0.0
**Last Updated:** 2025-01-07
**Swift Version:** 5.9+

---

## Quick Reference

| Example | Difficulty | Time | Type | Swift Version |
|---------|-----------|------|------|---------------|
| Async/Await | Beginner | 5 min | Generic | 5.5+ |
| Actors | Intermediate | 10 min | Generic | 5.5+ |
| @Observation | Beginner | 8 min | Generic | 5.9+ |
| Networking | Intermediate | 12 min | Generic | 5.5+ |
| Combine | Advanced | 15 min | Generic | 5.5+ (macOS 10.15+) |
| **HealthKit Service** | Advanced | 20 min | **Real Code** | 6.0+ |
| **Network Server** | Advanced | 25 min | **Real Code** | 6.0+ |
| **Pairing Service** | Advanced | 20 min | **Real Code** | 6.0+ |
| **Certificate Service** | Advanced | 15 min | **Real Code** | 6.0+ |

**Total time:** ~130 minutes for all examples (50 min generic + 80 min real code)

---

**Happy learning! 🚀**
