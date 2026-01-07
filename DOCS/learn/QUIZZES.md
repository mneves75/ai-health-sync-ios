# Chapter Quizzes: iOS Health Sync Learning Guide

**Test Your Understanding After Each Chapter**

---

## How to Use These Quizzes

1. **Complete after reading** each chapter
2. **Answer without looking** at the chapter
3. **Grade yourself** honestly
4. **Review missed questions** by re-reading relevant sections
5. **Retake quiz** in 2-3 days

> **Scoring:**
> - 90-100%: Excellent! Move to next chapter.
> - 70-89%: Good, but review missed questions.
> - <70%: Re-read chapter before continuing.

---

## Chapter 0: Learning Framework Quiz

### 1. What are the 5 steps of the Active Learning Framework?

A) Read → Write → Test → Grade → Repeat
B) Read → Active Recall → Practice → Teach Back → Apply
C) Listen → Memorize → Write → Test → Apply
D) Read → Highlight → Summarize → Review → Cram

**Correct Answer:** B

---

### 2. What is the Feynman Technique?

A) Learning by teaching others simply
B) Memorizing flashcards
C) Reading textbooks multiple times
D) Watching video tutorials

**Correct Answer:** A

---

### 3. What is dual coding?

A) Writing code in two languages
B) Combining text with visuals for better learning
C) Pair programming
D) Using two monitors

**Correct Answer:** B

---

### 4. How often should you review material for best retention?

A) Once per week
B) Only before exams
C) Tomorrow, 3 days, 1 week, 1 month (spaced repetition)
D) Every day forever

**Correct Answer:** C

---

### 5. What is the purpose of "Stop & Think" checkpoints?

A) To take breaks
B) To force active recall during reading
C) To skip hard sections
D) To check your phone

**Correct Answer:** B

---

**Your Score:** _____ / 5

---

## Chapter 1: What This App Does Quiz

### 1. What is the main purpose of the iOS Health Sync app?

A) To store health data in the cloud
B) To sync health data peer-to-peer between iPhone and Mac
C) To track workouts
D) To share health data on social media

**Correct Answer:** B

---

### 2. Which health data types does the app support? (Select all that apply)

A) Steps
B) Heart Rate
C) Sleep Analysis
D) Workouts
E) All of the above

**Correct Answer:** E

---

### 3. What is mTLS?

A) A type of database
B) Mutual authentication using certificates
C) A programming language
D) A cloud service

**Correct Answer:** B

---

### 4. How does pairing work?

A) Enter password on both devices
B) Scan QR code on iPhone with Mac
C) Bluetooth pairing
D) iCloud sync

**Correct Answer:** B

---

### 5. Why doesn't the app use cloud storage?

A) It's too expensive
B) Privacy, security, and user control
C) Cloud is unreliable
D) Apple doesn't allow it

**Correct Answer:** B

---

### 6. What protocol does the app use for device discovery?

A) DNS
B) HTTP
C) Bonjour (zero-configuration networking)
D) FTP

**Correct Answer:** C

---

### 7. What is the CLI companion used for?

A) Building the iOS app
B) Fetching health data from iPhone to Mac
C) Creating UI designs
D) Debugging the server

**Correct Answer:** B

---

**Your Score:** _____ / 7

---

## Chapter 2: Architecture Quiz

### 1. What are the 4 layers of the architecture? (In correct order)

A) Data → Business → Application → Presentation
B) Presentation → Application → Business → Data
C) UI → Services → Database → Network
D) Frontend → Backend → Database → API

**Correct Answer:** B

---

### 2. What is the Single Responsibility Principle?

A) Each component should do one thing well
B) Each class should have only one method
C) Each file should be small
D) Each function should be short

**Correct Answer:** A

---

### 3. What is dependency injection?

A) Creating dependencies inside classes
B) Passing dependencies from outside
C) Injecting code into running processes
D) A database technique

**Correct Answer:** B

---

### 4. What does AppState do?

A) Store health data
B) Coordinate services and manage UI state
C) Handle network requests
D) Draw UI components

**Correct Answer:** B

---

### 5. Why are all services actors?

A) To make code faster
B) To prevent data races
C) To use less memory
D) To simplify syntax

**Correct Answer:** B

---

### 6. What is the benefit of protocol-oriented design?

A) Easier to read
B) Testability and loose coupling
C) Faster compilation
D) Smaller binary size

**Correct Answer:** B

---

### 7. Which layer handles user input?

A) Data Layer
B) Business Layer
C) Presentation Layer
D) Application Layer

**Correct Answer:** C

---

### 8. What is tight coupling?

A) When components depend heavily on each other
B) When components are independent
C) When code is well-organized
D) When functions are short

**Correct Answer:** A

---

**Your Score:** _____ / 8

---

## Chapter 3: Swift 6 Concurrency Quiz

### 1. What is the difference between concurrency and parallelism?

A) They are the same thing
B) Concurrency is structure, parallelism is execution
C) Parallelism is structure, concurrency is execution
D) Neither exists in Swift

**Correct Answer:** B

---

### 2. What problem does async/await solve?

A) Memory management
B) Callback hell
C) Type safety
D) Network errors

**Correct Answer:** B

---

### 3. What is a data race?

A) A programming competition
B) Concurrent access to shared data without coordination
C) A type of sorting algorithm
D) A performance optimization

**Correct Answer:** B

---

### 4. How do actors prevent data races?

A) By making copies of data
B) By serializing access (one task at a time)
C) By using locks
D) By preventing all access

**Correct Answer:** B

---

### 5. What does Sendable mean?

A) Data can be emailed
B) Data is safe to pass between concurrent contexts
C) Data is public
D) Data is encrypted

**Correct Answer:** B

---

### 6. What does @Observable do?

A) Makes properties public
B) Automatically tracks property changes
C) Optimizes performance
D) Handles errors

**Correct Answer:** B

---

### 7. What is @MainActor used for?

A) Background processing
B) UI thread safety
C) Database operations
D) Network requests

**Correct Answer:** B

---

### 8. How do you bridge callbacks to async/await?

A) Use async/await directly
B) Use withCheckedThrowingContinuation
C) Use DispatchQueue
D) Rewrite the API

**Correct Answer:** B

---

### 9. Which types are automatically Sendable?

A) All classes
B) Value types (Int, String, struct)
C) Only actors
D) Nothing is automatic

**Correct Answer:** B

---

### 10. What happens when you await an actor method call?

A) The method runs in parallel
B) The current task suspends until the actor is available
C) The method is skipped
D) The app crashes

**Correct Answer:** B

---

**Your Score:** _____ / 10

---

## Chapter 4: SwiftUI Quiz

### 1. What is declarative UI?

A) Manually building UI elements
B) Describing what the UI should look like for given state
C) Using storyboards
D) Writing UI in XML

**Correct Answer:** B

---

### 2. How do you access AppState in a SwiftUI view?

A) @StateObject var appState
B) @Environment(\.appState) var appState
C) let appState = AppState()
D) @Published var appState

**Correct Answer:** B

---

### 3. What happens when an @Observable property changes?

A) Nothing happens
B) SwiftUI automatically updates views that use it
C) You must manually call updateUI()
D) The app crashes

**Correct Answer:** B

---

### 4. What is QRCodeView used for?

A) Displaying QR codes for pairing
B) Scanning QR codes
C) Generating QR codes
D) Storing QR codes

**Correct Answer:** A

---

**Your Score:** _____ / 4

---

## Chapter 5: SwiftData Quiz

### 1. What is SwiftData?

A) A database format
B) Apple's persistence framework
C) A cloud service
D) A data analysis tool

**Correct Answer:** B

---

### 2. What does @Model do?

A) Creates a 3D model
B) Marks a class for SwiftData persistence
C) Defines a database schema
D) Generates UI

**Correct Answer:** B

---

### 3. What is soft deletion?

A) Deleting data immediately
B) Marking as deleted with a timestamp
C) Moving to trash folder
D) Archiving old data

**Correct Answer:** B

---

### 4. Why is soft deletion important?

A) It's faster
B) Audit trails and data recovery
C) It uses less space
D) It's required by Swift

**Correct Answer:** B

---

**Your Score:** _____ / 4

---

## Chapter 6: HealthKit Quiz

### 1. What is HealthKit?

A) A fitness app
B) Apple's health data framework
C) A database
D) A cloud service

**Correct Answer:** B

---

### 2. Why does HealthKit require authorization?

A) To charge users
B) Privacy - users must grant permission
C) To track usage
D) It's a legal requirement

**Correct Answer:** B

---

### 3. What is HKSampleType?

A) A type of sample
B) Represents a category of health data
C) A database field
D) A user preference

**Correct Answer:** B

---

### 4. What does HealthSampleMapper do?

A) Maps health data to UI
B) Converts HKSample to HealthSampleDTO
C) Validates health data
D) Stores health data

**Correct Answer:** B

---

**Your Score:** _____ / 4

---

## Chapter 7: Security Quiz

### 1. What is Keychain?

A) A cryptographic key
B) iOS's secure storage for sensitive data
C) A blockchain
D) A password manager app

**Correct Answer:** B

---

### 2. What is mTLS?

A) Multi-threaded language
B) Mutual TLS authentication
C) A type of encryption
D) A network protocol

**Correct Answer:** B

---

### 3. What is a pairing token?

A) A password
B) One-time token in QR code for pairing
C) A certificate
D) A user ID

**Correct Answer:** B

---

### 4. Why is audit logging important?

A) Performance tracking
B) Compliance and security
C) User analytics
D) Debugging only

**Correct Answer:** B

---

**Your Score:** _____ / 4

---

## Chapter 8: Networking Quiz

### 1. What framework does the app use for the HTTP server?

A) URLSession
B) Network Framework (swift-nio)
C) Alamofire
D) AFNetworking

**Correct Answer:** B

---

### 2. What is TLS 1.3?

A) A programming language
B) The latest TLS version for encryption
C) A database
D) A UI framework

**Correct Answer:** B

---

### 3. How does the CLI discover iOS devices?

A) Manual IP entry
B) Bonjour (zero-configuration networking)
C) Bluetooth
D) GPS

**Correct Answer:** B

---

### 4. What is rate limiting?

A) Speed testing
B) Limiting requests to prevent abuse
C) Bandwidth throttling
D) A billing feature

**Correct Answer:** B

---

**Your Score:** _____ / 4

---

## Chapter 9: CLI Companion Quiz

### 1. What is ArgumentParser?

A) A command-line tool
B) Apple's Swift package for parsing CLI arguments
C) A text editor
D) A shell script

**Correct Answer:** B

---

### 2. Which command finds iOS devices on the network?

A) healthsync scan
B) healthsync discover
C) healthsync pair
D) healthsync fetch

**Correct Answer:** B

---

### 3. What does the `types` command do?

A) Lists available data types
B) Lists enabled data types in config
C) Validates data types
D) Converts data types

**Correct Answer:** B

---

**Your Score:** _____ / 3

---

## Chapter 10: Testing Quiz

### 1. What is Swift Testing?

A) Testing methodology
B) Apple's modern testing framework
C) A testing service
D) A code coverage tool

**Correct Answer:** B

---

### 2. What is protocol-based mocking?

A) Mocking protocols for testing
B) Creating fake implementations of protocols
C) Testing protocols
D) Documenting protocols

**Correct Answer:** B

---

### 3. What is the AAA pattern?

A) Always Act Assert
B) Arrange Act Assert
C) Automated Application Analysis
D) Assert Act Arrange

**Correct Answer:** B

---

### 4. What is code coverage?

A) Code documentation
B) Percentage of code executed by tests
C) Code quality metric
D) Performance metric

**Correct Answer:** B

---

**Your Score:** _____ / 4

---

## Comprehensive Final Quiz

### 1. Which Swift 6 feature prevents data races?

A) async/await
B) actors
C) Sendable
D) All of the above

**Correct Answer:** D

---

### 2. What is the app's architecture pattern?

A) MVC
B) MVVM
C) Layered Architecture (Clean Architecture)
D) Microservices

**Correct Answer:** C

---

### 3. How does the app ensure health data privacy?

A) Encryption (TLS 1.3, mTLS)
B) No cloud storage (peer-to-peer only)
C) Audit logging
D) All of the above

**Correct Answer:** D

---

### 4. What is the role of AppState?

A) Store health data
B) Coordinate services and manage UI state
C) Handle networking
D) Draw UI

**Correct Answer:** B

---

### 5. Why are all services actors?

A) Performance
B) Thread safety (prevent data races)
C) Memory efficiency
D) Simpler syntax

**Correct Answer:** B

---

### 6. What is soft deletion?

A) Permanent deletion
B) Marking deleted with timestamp
C) Moving to archive
D) Hiding from UI

**Correct Answer:** B

---

### 7. What protocol does the app use for device discovery?

A) HTTP
B) Bonjour
C) DNS
D) Bluetooth

**Correct Answer:** B

---

### 8. What is the purpose of @Observable?

A) Code organization
B) Automatic state tracking for SwiftUI
C) Performance optimization
D) Error handling

**Correct Answer:** B

---

### 9. How does pairing work?

A) Password exchange
B) QR code with mutual certificate exchange
C) Bluetooth pairing
D) iCloud sync

**Correct Answer:** B

---

### 10. What is the Feynman Technique?

A) Learning by teaching simply
B) Memorization technique
C) Speed reading
D) Note-taking method

**Correct Answer:** A

---

**Your Score:** _____ / 10

---

## Quiz Results Tracker

Track your quiz scores over time:

| Chapter | First Attempt | Second Attempt | Third Attempt | Mastery |
|---------|---------------|----------------|---------------|---------|
| Ch 0: Learning Framework | ____% | ____% | ____% | ☐ |
| Ch 1: What This App Does | ____% | ____% | ____% | ☐ |
| Ch 2: Architecture | ____% | ____% | ____% | ☐ |
| Ch 3: Swift 6 | ____% | ____% | ____% | ☐ |
| Ch 4: SwiftUI | ____% | ____% | ____% | ☐ |
| Ch 5: SwiftData | ____% | ____% | ____% | ☐ |
| Ch 6: HealthKit | ____% | ____% | ____% | ☐ |
| Ch 7: Security | ____% | ____% | ____% | ☐ |
| Ch 8: Networking | ____% | ____% | ____% | ☐ |
| Ch 9: CLI Companion | ____% | ____% | ____% | ☐ |
| Ch 10: Testing | ____% | ____% | ____% | ☐ |
| **Final Comprehensive** | ____% | ____% | ____% | ☐ |

**Mastery Criteria:** 90%+ on two consecutive attempts

---

## Study Recommendations

### If scoring below 70%:
1. Re-read the chapter slowly
2. Use the flashcards actively
3. Do all chapter exercises
4. Teach the concepts to someone else

### If scoring 70-89%:
1. Review missed questions only
2. Re-read specific sections
3. Practice with code exercises
4. Retake quiz in 2 days

### If scoring 90%+:
1. Excellent! Move to next chapter
2. Review in 1 week to巩固
3. Help teach others
4. Apply knowledge to real projects

---

**Remember:** Quizzes are for learning, not grading. Use them to identify gaps, then fill those gaps!
