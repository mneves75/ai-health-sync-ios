# Contributing to iOS Health Sync

**Thank you for considering contributing!** 🎉

We welcome contributions from everyone. This document provides guidelines for contributing to the iOS Health Sync project.

---

## 🚀 Quick Start for Contributors

**For first-time contributors:**
1. Read this document (5 minutes)
2. Set up development environment (10 minutes)
3. Find a good first issue (varies)
4. Make your changes (varies)
5. Submit pull request (5 minutes)

**Estimated total time:** 30 minutes for first contribution

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [What to Contribute](#what-to-contribute)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Documentation Standards](#documentation-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Review Process](#review-process)

---

## 🤝 Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all. Please:

- **Be respectful:** Treat others with dignity and respect
- **Be inclusive:** Welcome diverse perspectives and backgrounds
- **Be constructive:** Focus on what is best for the community
- **Be empathetic:** Show empathy toward other community members

### Unacceptable Behavior

- Harassment, discrimination, or exclusionary language
- Personal attacks or derogatory comments
- Public or private harassment
- Publishing others' private information
- Other unethical or unprofessional conduct

### Reporting Issues

Contact: Open an issue on GitHub with the `conduct` label.

---

## 🎯 What to Contribute

### Ways to Contribute

| Area | Examples | Time Commitment |
|------|----------|-----------------|
| **Bug Reports** | Report issues with reproduction steps | 5-15 min |
| **Feature Requests** | Propose new features with use cases | 10-30 min |
| **Documentation** | Improve docs, fix typos, add examples | 15-60 min |
| **Code** | Fix bugs, implement features | 1-4 hours |
| **Tests** | Add test coverage, fix failing tests | 30 min - 2 hours |
| **Review** | Review pull requests | 15-45 min |
| **Mentorship** | Help new contributors | Ongoing |

### Good First Issues

Look for issues labeled:
- `good first issue` - Suitable for newcomers
- `help wanted` - Community contributions welcome
- `documentation` - Documentation improvements

---

## 🛠️ Getting Started

### Prerequisites

**Required:**
- macOS 15 Sequoia or later
- Xcode 26 or later
- Swift 6.0+
- Git and GitHub account

**Helpful:**
- Familiarity with iOS development
- Experience with SwiftUI, HealthKit
- Knowledge of Swift concurrency (actors, async/await)

### Initial Setup

**1. Fork and Clone:**
```bash
# Fork the repository on GitHub
git clone https://github.com/YOUR_USERNAME/ai-health-sync-ios-clawdbot.git
cd ai-health-sync-ios-clawdbot
```

**2. Add Upstream Remote:**
```bash
git remote add upstream https://github.com/original-org/ai-health-sync-ios-clawdbot.git
```

**3. Open Xcode:**
```bash
# iOS dependencies (handled by Xcode)
open "iOS Health Sync App/iOS Health Sync App.xcodeproj"
```

**4. Build and Test:**
```bash
# Build iOS app
xcodebuild -project "iOS Health Sync App/iOS Health Sync App.xcodeproj" -scheme "iOS Health Sync App" build

# Run iOS tests
xcodebuild test -project "iOS Health Sync App/iOS Health Sync App.xcodeproj" -scheme "iOS Health Sync App"

# Build CLI (Swift Package)
cd macOS/HealthSyncCLI && swift build

# Run CLI tests
swift test
```

---

## 🔄 Development Workflow

### 1. Find Something to Work On

- Browse [issues](https://github.com/mneves75/ai-health-sync-ios/issues)
- Check [project board](https://github.com/mneves75/ai-health-sync-ios/projects)

### 2. Create a Branch

```bash
# From main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-number

# Examples:
git checkout -b feature/add-blood-oxygen-support
git checkout -b fix/123-heart-rate-crash
```

**Branch Naming:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `test/` - Test additions/changes
- `refactor/` - Code refactoring
- `perf/` - Performance improvements

### 3. Make Your Changes

**Coding Standards** (see below):
- Follow Swift 6 conventions
- Use actors for thread safety
- Write tests for new code
- Update documentation

### 4. Commit Your Changes

```bash
git add .
git commit -m "type(scope): description

More detailed explanatory text (if needed)

Refs: #issue-number"
```

**Commit Message Format:**
```
type(scope): subject

body (optional)

footer (optional)
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes

**Examples:**
```
feat(healthkit): Add blood oxygen support

Implement HKQuantityType(.oxygenSaturation) support
for fetching and displaying blood oxygen data.

Refs: #45
```

```
fix(networking): Handle certificate expiration

Check certificate expiration date before attempting
TLS handshake. Show user-friendly error when expired.

Fixes #123
```

### 5. Sync with Upstream

```bash
git fetch upstream
git rebase upstream/main
```

### 6. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 7. Create Pull Request

- Go to GitHub: https://github.com/mneves75/ai-health-sync-ios
- Click "Compare & pull request"
- Fill PR template (see below)
- Link related issues
- Request reviewers

---

## 📐 Coding Standards

### Swift Style Guide

**Follow Swift 6 conventions:**

**1. Naming:**
```swift
// ✅ GOOD: Clear, descriptive names
actor HealthKitService { }
func requestAuthorization(for types: [HealthDataType]) async throws -> Bool

// ❌ BAD: Unclear abbreviations
actor HKSvc { }
func reqAuth(for t: [HealthDataType]) async throws -> Bool
```

**2. Use actors for thread safety:**
```swift
// ✅ GOOD: Actor prevents data races
actor Counter {
    var count = 0
    func increment() { count += 1 }
}

// ❌ BAD: Class vulnerable to races
class Counter {
    var count = 0
    func increment() { count += 1 }
}
```

**3. Async/await over callbacks:**
```swift
// ✅ GOOD: Clean async/await
func fetchData() async throws -> Data {
    try await networkService.get()
}

// ❌ BAD: Nested callbacks
func fetchData(completion: @escaping (Data?) -> Void) {
    networkService.get { data in
        completion(data)
    }
}
```

**4. Sendable for concurrent data:**
```swift
// ✅ GOOD: Immutable Sendable struct
struct HealthSampleDTO: Sendable {
    let id: UUID
    let value: Double
}

// ❌ BAD: Mutable non-Sendable
class HealthSample {
    var id: UUID
    var value: Double
}
```

**5. @Observable for state:**
```swift
// ✅ GOOD: Modern @Observable
@Observable class AppState {
    var isServerRunning: Bool = false
}

// ❌ BAD: Old ObservableObject
class AppState: ObservableObject {
    @Published var isServerRunning: Bool = false
}
```

### File Organization

```
iOS Health Sync App/
├── App/                    # App lifecycle, state management
│   ├── AppState.swift
│   └── iOS_Health_Sync_AppApp.swift
├── Core/                   # Shared code
│   ├── Models/            # Data models
│   ├── DTO/               # Transfer objects
│   └── Utilities/         # Helper code
├── Features/              # Feature-specific code
│   ├── ContentView.swift
│   └── QRCodeView.swift
└── Services/              # Business logic
    ├── HealthKit/
    ├── Network/
    ├── Security/
    └── Audit/
```

### Code Quality

**John Carmack Principles:**
1. **Clarity over cleverness:** Code should be obvious
2. **Correctness first:** Make it work before making it fast
3. **No unnecessary complexity:** Simple solutions are better
4. **Practical examples:** Use real code, not toy examples

**Before committing, ask:**
- Is this code obvious to a junior developer?
- Would I understand this 6 months from now?
- Is there a simpler way to achieve the same result?
- Have I added tests for this code?

---

## 📝 Documentation Standards

### Code Comments

**When to comment:**
```swift
// ✅ GOOD: Comment WHY, not WHAT
// HealthKit requires main thread for sample type queries
// Use MainActor.run to safely access sampleType property
let readTypes = Set(await MainActor.run { types.compactMap { $0.sampleType } })

// ❌ BAD: Stating the obvious
// Create a set of read types
let readTypes = Set(...)
```

**Function documentation:**
```swift
/// Requests HealthKit authorization for specified data types.
///
/// - Parameter types: Array of health data types to access
/// - Returns: True if user granted authorization
/// - Throws: HealthError.authDenied if user denies
func requestAuthorization(for types: [HealthDataType]) async throws -> Bool {
    // implementation
}
```

### README Updates

**When updating README.md, include:**
- Why this change matters
- How users benefit
- Migration guide (if breaking change)
- Examples of new feature

### Documentation Structure

We follow the **Diataxis framework**:

| Content Type | Location | Purpose |
|--------------|----------|---------|
| **Tutorials** | `/docs/tutorials/` | Learning-oriented lessons |
| **How-to Guides** | `/docs/how-to/` | Goal-oriented steps |
| **Reference** | `/docs/reference/` | Technical specifications |
| **Explanation** | `/docs/explanation/` | Understanding context |

---

## 🧪 Testing Requirements

### Test Coverage

**Minimum requirements:**
- **Unit tests:** 80%+ coverage for business logic
- **Integration tests:** All service interactions
- **UI tests:** Critical user flows

**Running tests:**
```bash
# iOS tests
xcodebuild test -project "iOS Health Sync App/iOS Health Sync App.xcodeproj" \
  -scheme "iOS Health Sync App" -destination 'platform=iOS Simulator,name=iPhone 16'

# CLI tests (Swift Package)
cd macOS/HealthSyncCLI && swift test
```

### Writing Tests

**Use Swift Testing framework:**
```swift
import Testing

@Test("HealthKitService returns ok when authorization succeeds")
func authorizationSuccess() async throws {
    // Arrange
    let mockStore = MockHealthStore()
    mockStore.authorizationResult = .success(true)
    let service = HealthKitService(store: mockStore)

    // Act
    let result = try await service.requestAuthorization(for: [.steps])

    // Assert
    #expect(result == true)
}
```

**Test naming:**
```
"Component/Feature returns expected result when condition"
```

### Before Submitting

Run these checks:
```bash
# 1. Build
swift build

# 2. All tests pass
swift test

# 3. Lint (if using SwiftLint)
swiftlint lint

# 4. Format (if using SwiftFormat)
swiftformat .
```

---

## 🔀 Pull Request Process

### PR Template

When creating a PR, fill out this template:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tests added/updated
- [ ] All tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review performed
- [ ] Comments added to complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Commits follow conventional format

## Related Issues
Fixes #issue-number
Refs #issue-number
```

### PR Review Process

**What reviewers check:**
1. **Correctness:** Does the code work?
2. **Clarity:** Is the code obvious?
3. **Testing:** Are there adequate tests?
4. **Documentation:** Is documentation updated?
5. **Style:** Does it follow conventions?

**Timeline:**
- Initial review: 1-3 days
- Follow-up reviews: 24 hours
- Complex PRs: Longer timeline

### Addressing Review Feedback

**When making changes:**
```bash
# Make requested changes
git add .
git commit -m "fix: address reviewer feedback

- Changed X to Y as suggested
- Added test for edge case
- Updated docs"
git push
```

**Responding to comments:**
- Address each point
- Explain if you disagree (respectfully)
- Mark resolved comments as done

---

## 👥 Review Process

### Becoming a Reviewer

**Requirements:**
- 5+ merged PRs
- Understanding of codebase
- Active community participation

**Responsibilities:**
- Review 2-4 PRs per month
- Provide constructive feedback
- Mentor new contributors

### Review Guidelines

**Be constructive:**
```markdown
✅ GOOD:
"I suggest using an actor here to prevent potential data races.
Here's an example: [code snippet]
Would you like help implementing this?"

❌ BAD:
"This is wrong. Use actors."
```

**Focus on:**
1. Code correctness and safety
2. Clarity and maintainability
3. Test coverage
4. Documentation

---

## 🏆 Recognition

**Contributors are recognized for:**
- First PR: Welcome message in Discord
- 5+ PRs: Contributor badge
- 10+ PRs: Maintainer consideration
- Major contributions: Special thanks in release notes

---

## 🚀 Release Process

### Creating a Release

Releases are automated via GitHub Actions. To create a new release:

```bash
# 1. Update CHANGELOG.md with new version
# 2. Commit changes
git add CHANGELOG.md
git commit -m "chore: prepare release v1.x.x"

# 3. Create and push tag
git tag -a v1.x.x -m "Release v1.x.x"
git push origin v1.x.x
```

The workflow will automatically:
- Build arm64 and x86_64 binaries
- Create GitHub Release with binaries and source archive
- Update Homebrew tap formula with new SHA256 hashes

### Publishing Skills to ClawdHub

To publish the Agent Skill to ClawdHub:

```bash
# Package the skill
./scripts/package-clawdhub.sh 1.0.0

# Options:
./scripts/package-clawdhub.sh --help      # Show usage
./scripts/package-clawdhub.sh --dry-run   # Preview without creating zip
```

Then upload at https://clawdhub.com/publish

See `skills/healthkit-sync/HOWTO_CLAWDHUB.md` for detailed instructions.

---

## 📚 Additional Resources

- [Architecture Overview](DOCS/learn/02-architecture.md)
- [Testing Guide](DOCS/learn/10-testing.md)
- [CLI Reference](DOCS/learn/09-cli.md)
- [Security Guide](DOCS/learn/07-security.md)

---

## ❓ Questions?

- **GitHub Issues:** [Open an issue](https://github.com/mneves75/ai-health-sync-ios/issues)
- **Discussions:** [GitHub Discussions](https://github.com/mneves75/ai-health-sync-ios/discussions)

---

**Thank you for contributing!** 🙏

Your contributions make iOS Health Sync better for everyone.

---

**Last Updated:** 2026-01-07
**Contributing Guide Version:** 1.0.0
