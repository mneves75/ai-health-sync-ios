# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

iOS Health Sync - Secure peer-to-peer HealthKit sync between iPhone and Mac. No cloud.

## Applicable Skills

IMPORTANT: Invoke these skills when working on this project:

**Core Standards:**
- `mneves-swift` - Swift 6, concurrency, Swift Testing, privacy manifests
- `mneves-dev-standards` - Code quality, type safety, John Carmack standard
- `mneves-security` - For security-sensitive changes

**Swift/SwiftUI (dimillian):**
- `dimillian-ios-debugger-agent` - Build, run, debug on simulator via XcodeBuildMCP
- `dimillian-swift-concurrency-expert` - Swift 6 concurrency review and remediation
- `dimillian-swiftui-liquid-glass` - iOS 26+ Liquid Glass UI implementation
- `dimillian-swiftui-ui-patterns` - SwiftUI best practices and component patterns
- `dimillian-swiftui-view-refactor` - Refactor SwiftUI views for structure/DI/@Observable
- `dimillian-swiftui-performance-audit` - Diagnose slow rendering, excessive updates
- `dimillian-app-store-changelog` - Generate App Store release notes from git history

## Commands

```bash
# Build iOS app
xcodebuild -project "iOS Health Sync App/iOS Health Sync App.xcodeproj" \
  -scheme "iOS Health Sync App" -destination 'generic/platform=iOS' build

# Run iOS tests (all)
xcodebuild test -project "iOS Health Sync App/iOS Health Sync App.xcodeproj" \
  -scheme "HealthSyncTests" -destination 'platform=iOS Simulator,name=iPhone 16'

# Run single iOS test
xcodebuild test -project "iOS Health Sync App/iOS Health Sync App.xcodeproj" \
  -scheme "HealthSyncTests" -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:iOS_Health_Sync_AppTests/<TestClass>/<testMethod>

# macOS CLI
cd macOS/HealthSyncCLI && swift build && swift test
```

## Gotchas

IMPORTANT - Know these before coding:
- HealthKit READ permissions CANNOT be verified - Apple hides denial for privacy
- Simulator has limited HealthKit data - test on device for real scenarios
- CLI requires macOS 15+ for Network framework TLS features
- All secrets in Keychain via `KeychainStore` - NEVER in config files or UserDefaults
- All health data access MUST be logged via `AuditService`

## Entry Points

| Component | File |
|-----------|------|
| iOS state | `iOS Health Sync App/iOS Health Sync App/App/AppState.swift` |
| HTTP server | `iOS Health Sync App/iOS Health Sync App/Services/Network/NetworkServer.swift` |
| TLS certs | `iOS Health Sync App/iOS Health Sync App/Services/Security/CertificateService.swift` |
| Health queries | `iOS Health Sync App/iOS Health Sync App/Services/HealthKit/HealthKitService.swift` |
| CLI | `macOS/HealthSyncCLI/Sources/HealthSyncCLI/main.swift` |

## Deep Dives

- Architecture: `DOCS/learn/02-architecture.md`
- Security: `DOCS/learn/07-security.md`
- Swift 6 patterns: `DOCS/learn/03-swift6.md`
- Testing: `DOCS/learn/10-testing.md`
- CLI usage: `DOCS/learn/09-cli.md`
