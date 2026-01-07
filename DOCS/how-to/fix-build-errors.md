# Fix Build Errors: Resolve Common Compilation Issues

**Troubleshoot and fix Xcode build failures**

---

**Time:** 10-30 minutes (varies)
**Difficulty:** Beginner to Intermediate
**Prerequisites:**
- [ ] Xcode 26 installed
- [ ] Project open in Xcode

---

## Goal

Diagnose and fix common build errors when compiling the iOS Health Sync app.

---

## Quick Diagnosis

**What error do you see?**

| Error Type | Go To |
|------------|-------|
| "No such module" | [Module Not Found](#module-not-found) |
| "CompileSwift failed" | [Swift Compiler Errors](#swift-compiler-errors) |
| "Code signing" | [Code Signing Issues](#code-signing-issues) |
| "Linker error" | [Linker Errors](#linker-errors) |
| "Cannot find type" | [Type Not Found](#type-not-found) |
| Build hangs | [Build Performance](#build-performance) |

---

## Module Not Found

### Error: "No such module 'SwiftData'"

**Cause:** SwiftData framework not linked or deployment target too low.

**Solution:**

1. **Check deployment target:**
   - Select project in Navigator
   - TARGETS → General → Minimum Deployments
   - Set iOS to **17.0** or higher

2. **Link framework:**
   - TARGETS → Build Phases → Link Binary With Libraries
   - Click + and add SwiftData

3. **Clean and rebuild:**
   ```bash
   # Clean build folder
   xcodebuild clean -project "iOS Health Sync App.xcodeproj"

   # Rebuild
   xcodebuild build -project "iOS Health Sync App.xcodeproj" -scheme "iOS Health Sync App"
   ```

---

### Error: "No such module 'HealthKit'"

**Cause:** HealthKit capability not enabled.

**Solution:**

1. Select target → Signing & Capabilities
2. Click + Capability
3. Add HealthKit

---

## Swift Compiler Errors

### Error: "Cannot convert value of type X to Y"

**Cause:** Type mismatch in assignment or function call.

**Solution:**

```swift
// Before (error)
let count: Int = someString

// After (fixed)
let count: Int = Int(someString) ?? 0
```

---

### Error: "Value of type 'X' has no member 'Y'"

**Cause:** Typo in property/method name or wrong type.

**Solution:**

1. Check spelling
2. Verify type is correct
3. Check import statements

```swift
// Before (error)
healthStore.fetchSample(...)

// After (fixed - correct method name)
healthStore.fetchSamples(...)
```

---

### Error: "Actor-isolated property cannot be accessed from non-isolated context"

**Cause:** Swift 6 strict concurrency - accessing actor property without await.

**Solution:**

```swift
// Before (error)
let value = myActor.someProperty

// After (fixed)
let value = await myActor.someProperty
```

Or mark the calling context appropriately:

```swift
// Make the function async
func doSomething() async {
    let value = await myActor.someProperty
}
```

---

### Error: "Sending 'X' risks causing data races"

**Cause:** Non-Sendable type crossing actor boundaries.

**Solution:**

```swift
// Make the type Sendable
struct MyData: Sendable {
    let value: String
}

// Or use @unchecked Sendable for classes (carefully)
final class MyClass: @unchecked Sendable {
    // Ensure thread-safe implementation
}
```

---

## Code Signing Issues

### Error: "Signing requires a development team"

**Solution:**

1. Select project → Signing & Capabilities
2. Sign in with Apple ID in Xcode → Settings → Accounts
3. Select your team from dropdown

---

### Error: "Provisioning profile doesn't include capability"

**Solution:**

1. Enable capability in Xcode first
2. Xcode will update provisioning profile automatically
3. Or regenerate profile in Apple Developer Portal

---

### Error: "Code signing blocked mmap()"

**Cause:** Running unsigned code on device.

**Solution:**

1. Ensure "Automatically manage signing" is enabled
2. Trust developer on device: Settings → General → Device Management

---

## Linker Errors

### Error: "Undefined symbol"

**Cause:** Missing framework or library.

**Solution:**

1. Check Build Phases → Link Binary With Libraries
2. Add missing framework
3. For Swift packages, check Package Dependencies

```bash
# Example: Add missing framework
# Project Navigator → TARGETS → Build Phases → Link Binary With Libraries → +
```

---

### Error: "Library not found for -lXXX"

**Cause:** Library path incorrect or library not installed.

**Solution:**

1. Check Build Settings → Library Search Paths
2. Verify library exists at that path
3. For CocoaPods/SPM, re-run package resolution

---

## Type Not Found

### Error: "Cannot find type 'HealthDataType' in scope"

**Cause:** Missing import or file not in target.

**Solution:**

1. **Add import:**
   ```swift
   import Foundation
   @testable import iOS_Health_Sync_App
   ```

2. **Check file is in target:**
   - Select file in Navigator
   - Check Target Membership in File Inspector
   - Ensure correct target is checked

---

## Build Performance

### Build Hangs or Very Slow

**Solutions:**

1. **Clean derived data:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

2. **Disable index while building:**
   - Xcode → Settings → General → Show Index Build options
   - Enable "Show Build Phase Timing"

3. **Check for recursive imports:**
   - Avoid circular dependencies between files

4. **Use incremental builds:**
   ```bash
   # Don't clean every time
   xcodebuild build  # Not: xcodebuild clean build
   ```

---

## General Troubleshooting Steps

### Step 1: Clean Build

```bash
# In Xcode: Shift+Cmd+K
# Or terminal:
xcodebuild clean -project "iOS Health Sync App/iOS Health Sync App.xcodeproj"
```

### Step 2: Delete Derived Data

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### Step 3: Resolve Package Dependencies

In Xcode: File → Packages → Reset Package Caches

### Step 4: Restart Xcode

Sometimes Xcode needs a fresh start.

### Step 5: Check Xcode Version

```bash
xcodebuild -version
# Should be Xcode 26.x
```

### Step 6: Update Command Line Tools

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

---

## CLI Build Errors

### Error: "swift build failed"

**Solution:**

```bash
cd macOS/HealthSyncCLI

# Clean
swift package clean

# Resolve dependencies
swift package resolve

# Build
swift build
```

### Error: "Package.swift not found"

**Cause:** Not in correct directory.

**Solution:**

```bash
# Navigate to CLI directory
cd macOS/HealthSyncCLI
ls Package.swift  # Should exist

swift build
```

---

## Verification

**After fixing errors:**

```bash
# Build iOS app
xcodebuild build \
  -project "iOS Health Sync App/iOS Health Sync App.xcodeproj" \
  -scheme "iOS Health Sync App" \
  -destination 'generic/platform=iOS'

# Build CLI
cd macOS/HealthSyncCLI && swift build
```

**Success:** "Build Succeeded" message.

---

## See Also

- [Install Prerequisites](./install-prerequisites.md) - Setup guide
- [Troubleshooting](../TROUBLESHOOTING.md) - General issues
- [Architecture](../reference/architecture.md) - System overview

---

**Last Updated:** 2026-01-07
