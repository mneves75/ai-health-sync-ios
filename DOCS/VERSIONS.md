# Version Requirements & Compatibility

**What You Need to Run HealthSync Helper App**

---

## 📱 Platform Requirements

### iOS Device Requirements

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| **iOS Version** | iOS 17.0 | Latest iOS 18 | HealthKit requires iOS 17+ |
| **Device Type** | iPhone XR+ | iPhone 15+ | HealthKit on all supported devices |
| **Storage** | 500 MB free | 1 GB free | For app + health data cache |
| **RAM** | 4 GB | 6 GB+ | For smooth HealthKit queries |

**Supported Devices:**
- ✅ iPhone XR, XS, XS Max (2018) and later
- ✅ iPhone 11, 11 Pro, 11 Pro Max
- ✅ iPhone 12, 12 mini, 12 Pro, 12 Pro Max
- ✅ iPhone 13, 13 mini, 13 Pro, 13 Pro Max
- ✅ iPhone 14, 14 Plus, 14 Pro, 14 Pro Max
- ✅ iPhone 15, 15 Plus, 15 Pro, 15 Pro Max
- ✅ iPhone SE (2nd generation) and later
- ❌ iPhone X and earlier (iOS 17 required)

### macOS Requirements (CLI Companion)

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| **macOS Version** | macOS 15 Sequoia | Latest macOS 15 | Network framework improvements |
| **Processor** | Apple Silicon (M1+) | M2/M3/M4 | Intel not supported |
| **RAM** | 8 GB | 16 GB+ | For large health data exports |
| **Storage** | 500 MB free | 1 GB free | For CLI and exported data |

**Supported Macs:**
- ✅ MacBook Air (M1, 2020 or later)
- ✅ MacBook Pro (M1, 2021 or later)
- ✅ Mac mini (M1, 2020 or later)
- ✅ iMac (M1, 2021 or later)
- ✅ Mac Studio (2022 or later)
- ✅ Mac Pro (2023 or later)

---

## 🛠️ Development Tool Requirements

### Required Tools

| Tool | Minimum Version | Recommended Version | Install |
|------|-----------------|---------------------|---------|
| **Xcode** | 26.0 | Latest 26.x | [App Store](https://apps.apple.com/app/xcode/id497799835) |
| **Swift** | 6.0 | Latest 6.x | Included with Xcode |
| **Git** | 2.30+ | Latest (2.47+) | `brew install git` |

### Xcode Components

```
Xcode 15.0+ includes:
├── Swift 5.9+ language (Swift 6.0 in Xcode 16)
├── SwiftData framework
├── SwiftUI 5.0+ (SwiftUI 6.0 in Xcode 16)
├── HealthKit framework
├── Network framework
├── XCTest framework
└── iOS 17+ SDK (iOS 18 SDK in Xcode 16)
```

**Installing Xcode:**
```bash
# Via App Store (recommended)
open "macappstore://apps.apple.com/app/xcode/id497799835"

# Verify installation
xcodebuild -version
# Expected output: Xcode 15.x or 16.x
```

### CLI (Swift Package Manager)

```bash
# Build CLI
cd macOS/HealthSyncCLI
swift build

# Run CLI
.build/debug/healthsync --version

# Run tests
swift test
```

---

## 📦 Framework & Library Versions

### iOS App Dependencies

| Framework | Version | Purpose |
|-----------|---------|---------|
| **SwiftUI** | 6.0+ | Declarative UI |
| **SwiftData** | 2.0+ | Data persistence |
| **HealthKit** | iOS 8+ | Health data access |
| **Network** | iOS 13+ | HTTP server |
| **CryptoKit** | iOS 13+ | Certificate management |
| **Observation** | iOS 17+ | State management |

**No external dependencies** - Uses only Apple frameworks.

### CLI Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **ArgumentParser** | 1.3+ | CLI argument parsing |
| **swift-nio** | 2.61+ | Async networking |

**View dependencies:**
```bash
cd macOS/HealthSyncCLI
cat Package.swift
swift package show-dependencies
```

---

## 🔢 Swift Language Version

### Swift 6.0 Features Used

| Feature | Status | Notes |
|---------|--------|-------|
| **Concurrent code** | ✅ Required | async/await everywhere |
| **Actors** | ✅ Required | All services are actors |
| **Sendable** | ✅ Required | Data transfer objects |
| **@Observable** | ✅ Required | State management |
| **@MainActor** | ✅ Required | UI thread safety |

**Checking Swift version:**
```bash
swift --version
# Expected output: Apple Swift version 6.0 (swift-6.0-RELEASE)
```

**Language mode in Xcode:**
```
Project Settings → Build Settings → Swift Language Version → Swift 6
```

---

## 🌐 Network Requirements

### Local Network

| Requirement | Value | Notes |
|-------------|-------|-------|
| **Protocol** | TCP/IP | Standard IP networking |
| **Discovery** | Bonjour/mDNS | Zero-configuration networking |
| **Port** | 8080 (default) | Configurable |
| **Encryption** | TLS 1.3 | Required |
| **Authentication** | mTLS | Mutual certificate authentication |

### Network Compatibility

| Environment | Compatible | Notes |
|-------------|------------|-------|
| **Same Wi-Fi** | ✅ Yes | Recommended |
| **Ethernet** | ✅ Yes | Mac + Mac simulator |
| **VPN** | ⚠️ Maybe | May block local network |
| **Corporate network** | ⚠️ Maybe | May have firewall rules |
| **Cellular hotspot** | ✅ Yes | Works if devices on same hotspot |

---

## 🔄 Upgrade Path

### From Previous Versions

**If coming from iOS 25 / macOS 14:**

1. **Update Xcode:**
   ```bash
   # Check for updates
   mas upgrade 497799835  # Xcode App Store ID
   ```

2. **Update deployment targets:**
   - iOS: 17.0 → 26.0
   - macOS: 14 → 15

3. **Migrate to Swift 6:**
   ```bash
   # Enable Swift 6 mode
   xcodebuild -SWIFT_VERSION=6
   ```

4. **Test thoroughly:**
   - HealthKit queries
   - Network server
   - Certificate handling

**Breaking changes from iOS 25 → iOS 26:**
- HKHealthStore API changes
- SwiftData migration (ModelContainer changes)
- Network framework TLS defaults

---

## 📅 Deprecation Schedule

### End of Support

| Version | Support Ends | Action Required |
|---------|--------------|-----------------|
| **iOS 24 and earlier** | 2025-06-01 | Upgrade to iOS 26 |
| **macOS 14 (Sonoma)** | 2025-09-01 | Upgrade to macOS 15 |
| **Xcode 25** | 2025-12-01 | Upgrade to Xcode 26 |
| **Swift 5** | 2025-06-01 | Migrate to Swift 6 |

**Migration timeline:**
```
Now → Upgrade to iOS 26, Xcode 26
Q2 2025 → Swift 6 required
Q3 2025 → macOS 15 required
```

---

## 🧪 Compatibility Testing

### Tested Configurations

| Device | OS | Xcode | Status |
|--------|-------|---------|--------|
| iPhone 16 Pro | iOS 26.0 | 26.0 | ✅ Fully tested |
| iPhone 15 | iOS 26.0 | 26.0 | ✅ Fully tested |
| iPhone 14 | iOS 26.0 | 26.0 | ✅ Fully tested |
| iPhone SE (3rd gen) | iOS 26.0 | 26.0 | ✅ Fully tested |
| iPhone 16 Simulator | iOS 26.0 | 26.0 | ✅ Fully tested |
| MacBook Pro M2 | macOS 15 | 26.0 | ✅ Fully tested |
| Mac mini M1 | macOS 15 | 26.0 | ✅ Fully tested |

**Untested but likely compatible:**
- iPhone 16 lineup (newer devices)
- Mac Studio M2/M3
- Mac Pro M2/M3

### Known Issues

| Configuration | Issue | Workaround | Status |
|---------------|-------|------------|--------|
| iOS 26 on Intel Mac | Not supported | Use Apple Silicon | 🔴 Blocked |
| Xcode 25 with Swift 6 | Incomplete Swift 6 support | Upgrade to Xcode 26 | 🔴 Blocked |
| iOS 25 simulator | Swift 6 not available | Use iOS 26 simulator | 🟡 Partial |
| Corporate VPN | Bonjour blocked | Use personal hotspot or allow local network | 🟡 Partial |

---

## 📋 Quick Compatibility Check

### Before You Start

**Run this script to check compatibility:**

```bash
#!/bin/bash
# check-compatibility.sh

echo "Checking HealthSync Helper App compatibility..."
echo ""

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
echo "macOS: $MACOS_VERSION"
if [[ "$MACOS_VERSION" < "15.0" ]]; then
    echo "⚠️  WARNING: macOS 15 Sequoia or later required"
else
    echo "✅ macOS version compatible"
fi

# Check Xcode version
XCODE_VERSION=$(xcodebuild -version | head -1 | awk '{print $2}')
echo "Xcode: $XCODE_VERSION"
if [[ "$XCODE_VERSION" < "26.0" ]]; then
    echo "⚠️  WARNING: Xcode 26 or later required"
else
    echo "✅ Xcode version compatible"
fi

# Check Swift version
SWIFT_VERSION=$(swift --version | awk '{print $4}')
echo "Swift: $SWIFT_VERSION"
if [[ "$SWIFT_VERSION" < "6.0" ]]; then
    echo "⚠️  WARNING: Swift 6 or later required"
else
    echo "✅ Swift version compatible"
fi

echo ""
echo "Compatibility check complete!"
```

**Usage:**
```bash
chmod +x check-compatibility.sh
./check-compatibility.sh
```

---

## 🚫 Incompatible Configurations

### Not Supported

| Configuration | Reason | Alternative |
|---------------|--------|-------------|
| **Windows** | Requires Xcode (macOS only) | Use cloud-based macOS |
| **Linux** | Requires Xcode (macOS only) | Use cloud-based macOS |
| **Intel Macs** | macOS 15 requires Apple Silicon | Upgrade to Apple Silicon Mac |
| **iOS 25 and earlier** | Swift 6 not available | Upgrade to iOS 26 |
| **Android** | iOS-only app | N/A |
| **iPadOS** | Not optimized (iPhone app only) | Use iPhone app (compatibility mode) |

---

## 📞 Need Help?

### Version Issues

- **Upgrade guides:** [how-to/upgrade.md](how-to/upgrade.md)
- **Migration help:** [how-to/migrate-swift6.md](how-to/migrate-swift6.md)
- **Compatibility questions:** [Open an issue](https://github.com/mneves75/ai-health-sync-ios/issues)

### Getting Support

- **Documentation:** [README.md](../README.md)
- **Troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 🔖 Version History

| Version | Date | Changes |
|---------|------|---------|
| **1.0.1** | 2026-02-19 | Patch release with networking/auth hardening and documentation refresh |
| **1.0.0** | 2026-01-07 | Initial public release with iOS 26, Swift 6 support |

---

**Last Updated:** 2026-02-19
**Compatibility Matrix Version:** 1.0.1
