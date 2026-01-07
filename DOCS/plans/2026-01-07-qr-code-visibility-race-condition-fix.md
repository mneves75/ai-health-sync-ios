# Exec Spec: QR Code Visibility and Race Condition Fixes

## Context
The iOS app's QR code pairing flow had three critical bugs:
1. **SIGSEGV crash** during app state transitions (backgrounding/foregrounding)
2. **QR code invisible** in dark mode - black modules on transparent background
3. **Race condition** where Copy/Share captured old payload while Refresh was in progress

## Root Cause Analysis

### Bug 1: SIGSEGV Crash (Swift Bug #74037)
- **Symptom**: App crashed when backgrounding/foregrounding or locking/unlocking device
- **Root Cause**: `@objc` NotificationCenter selectors on `@MainActor @Observable` class
- **Technical Detail**: Swift 6's actor isolation conflicts with Objective-C runtime's selector dispatch
- **File**: `AppState.swift`

### Bug 2: QR Code Invisible in Dark Mode
- **Symptom**: QR code appeared blank/invisible in dark mode
- **Root Cause**: `CIQRCodeGenerator` outputs black modules on TRANSPARENT background
- **Technical Detail**: In dark mode, black-on-transparent is invisible against dark UI
- **File**: `QRCodeRenderer.swift`

### Bug 3: Copy/Share Race Condition
- **Symptom**: User copies QR, then sees different code on screen; clipboard has old code
- **Root Cause**: Button closures capture `payload` at render time. Async refresh changes state mid-operation.
- **Technical Detail**:
  1. User sees QR A, taps Refresh (async task starts)
  2. User taps Copy (uses OLD captured payload A)
  3. Refresh completes (QR changes to B)
  4. User sees B on screen but clipboard has A
- **Files**: `ContentView.swift`, `AppState.swift`

## Fixes Implemented

### Fix 1: NotificationCenter Observers
**Before** (crashed):
```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleProtectedDataAvailable),
    name: UIApplication.protectedDataDidBecomeAvailableNotification,
    object: nil
)

@objc private func handleProtectedDataAvailable() { ... }
```

**After** (safe):
```swift
notificationTask = Task { [weak self] in
    await withTaskGroup(of: Void.self) { group in
        group.addTask { [weak self] in
            for await _ in NotificationCenter.default.notifications(
                named: UIApplication.protectedDataDidBecomeAvailableNotification
            ) {
                await self?.handleProtectedDataAvailable()
            }
        }
        // ... other notifications
    }
}

private func handleProtectedDataAvailable() { ... }  // No @objc needed
```

### Fix 2: QR Code White Background
**Before** (invisible in dark mode):
```swift
// CIQRCodeGenerator outputs black on TRANSPARENT
guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { ... }
return UIImage(cgImage: cgImage)
```

**After** (visible in all modes):
```swift
guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { ... }

// Draw on explicit white background
let size = CGSize(width: scaled.extent.width, height: scaled.extent.height)
let renderer = UIGraphicsImageRenderer(size: size)
let finalImage = renderer.image { ctx in
    UIColor.white.setFill()
    ctx.fill(CGRect(origin: .zero, size: size))
    UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: size))
}
return finalImage
```

### Fix 3: Disable Copy/Share During Refresh
**AppState.swift**:
```swift
var isRefreshing: Bool = false

func refreshPairingCode() async {
    guard isServerRunning else { return }
    isRefreshing = true
    defer { isRefreshing = false }
    // ... generate new QR code
}
```

**ContentView.swift**:
```swift
Button {
    HapticFeedback.impact(.light)
    Task { await appState.refreshPairingCode() }
} label: {
    if appState.isRefreshing {
        HStack(spacing: 6) {
            ProgressView().controlSize(.small)
            Text("Refreshing")
        }
    } else {
        Label("Refresh", systemImage: "arrow.clockwise")
    }
}
.disabled(appState.isRefreshing)

// Copy and Share buttons
Button { ... }
.disabled(appState.isRefreshing)  // Prevents race condition
```

## Technical Decisions

1. **UIGraphicsImageRenderer over CIImage compositing**: More reliable, works on all threads, explicit control over output format
2. **`defer` for state reset**: Guarantees `isRefreshing` is reset even if async operation throws
3. **Async notification pattern**: Uses Swift Concurrency's `NotificationCenter.default.notifications(named:)` for actor-safe notification handling
4. **No caching in QRCodeView**: Removed `@State` caching to eliminate stale QR display bugs

## Files Modified
- `iOS Health Sync App/App/AppState.swift` - NotificationCenter fix + isRefreshing state
- `iOS Health Sync App/Core/Utilities/QRCodeRenderer.swift` - White background rendering
- `iOS Health Sync App/Features/QRCodeView.swift` - Simplified to direct rendering
- `iOS Health Sync App/ContentView.swift` - Button disable during refresh
- `CHANGELOG.md` - Version 1.0.0 release notes

### Fix 4: Button Icons Not Displaying
**Root cause**: iOS 26's `.glass` and `.glassProminent` button styles don't render the icon portion of `Label` components.

**Before** (icons hidden):
```swift
Button {
    // action
} label: {
    Label("Request HealthKit Access", systemImage: "heart.fill")
}
.liquidGlassButtonStyle(.prominent)
```

**After** (icons visible):
```swift
Button {
    // action
} label: {
    HStack(spacing: 8) {
        Image(systemName: "heart.fill")
        Text("Request HealthKit Access")
    }
}
.liquidGlassButtonStyle(.prominent)
```

## Verification
- [x] Build succeeds on iOS Simulator
- [x] QR code visible in light and dark mode
- [x] Refresh shows loading indicator
- [x] Copy/Share disabled during refresh
- [x] Pairing code updates correctly after refresh
- [x] Button icons display correctly with Liquid Glass styles

## Acceptance Criteria
- QR code renders with white background on all color schemes
- No crash during app lifecycle transitions
- Copy/Share buttons disabled while refresh is in progress
- Refresh button shows "Refreshing..." with spinner during operation
- Clipboard content always matches what was displayed at time of copy
- All buttons show SF Symbol icons alongside text
