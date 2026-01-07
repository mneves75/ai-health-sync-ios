# iOS Health Sync

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2026%20%7C%20macOS%2015-lightgrey.svg)](https://developer.apple.com)
[![Release](https://img.shields.io/github/v/release/mneves75/ai-health-sync-ios)](https://github.com/mneves75/ai-health-sync-ios/releases)

**Secure, peer-to-peer Apple HealthKit data sync between iPhone and Mac**

---

## 🎯 What is iOS Health Sync?

iOS Health Sync enables **secure, local-only** health data synchronization between your iPhone and Mac using modern Apple technologies—no cloud services required.

**Two components:**
1. **iOS App** - Runs a local TLS server serving HealthKit data
2. **macOS CLI** - Connects to iOS app to retrieve and export health data

**Key Features:**
- 🔒 **Secure by Design** - TLS 1.3 encryption with mutual certificate authentication
- 🏠 **Local Network Only** - Data never leaves your devices
- 📱 **Easy Pairing** - Scan QR code to establish trusted connection
- 🏥 **HealthKit Integration** - Access steps, heart rate, sleep, workouts, and more

---

## 🚀 Quick Start

**Get running in 10 minutes**

### Prerequisites

- ✅ macOS 15 Sequoia or later
- ✅ Xcode 26 or later (Swift 6 required)
- ✅ iOS 26+ Simulator or physical device
- ✅ Apple Silicon Mac (M1 or later)

**Need details?** See [Full Prerequisites](DOCS/VERSIONS.md)

---

### Step 1: Clone and Build iOS App

```bash
git clone https://github.com/mneves75/ai-health-sync-ios.git
cd ai-health-sync-ios
open "iOS Health Sync App/iOS Health Sync App.xcodeproj"
```

In Xcode: Press **⌘R** to build and run on iPhone 16 simulator.

---

### Step 2: Install macOS CLI

**Option A: Homebrew (Recommended)**

```bash
brew tap mneves75/tap
brew install healthsync
```

**Option B: Download from Release**

Download pre-built binaries from [GitHub Releases](https://github.com/mneves75/ai-health-sync-ios/releases):
- Apple Silicon (M1/M2/M3): `healthsync-VERSION-macos-arm64.tar.gz`
- Intel: `healthsync-VERSION-macos-x86_64.tar.gz`

**Option C: Build from Source**

```bash
cd macOS/HealthSyncCLI
swift build -c release
# Binary at: .build/release/healthsync
```

**Note:** The CLI is a Swift Package - use `swift build` (not npm/bun).

---

### Step 3: Pair Devices

1. **On iOS App:** Tap "Start Server" → "Show QR Code"
2. **On Mac CLI:**
   ```bash
   healthsync scan  # Scans QR from clipboard
   ```

---

### Step 4: Fetch Health Data

```bash
healthsync fetch --types steps --start 2026-01-01
```

**✅ Success!** You now have your health data on your Mac.

---

**Need help?** See [Quick Start Guide](DOCS/QUICKSTART.md), [Getting Started Checklist](DOCS/GETTING-STARTED-CHECKLIST.md), or [Troubleshooting](DOCS/TROUBLESHOOTING.md)

---

## 📚 Documentation

**We've created comprehensive documentation following the [Diataxis framework](https://diataxis.fr/).**

### By Goal

| Goal | Documentation |
|------|----------------|
| **Get Started Fast** | [Quick Start Guide](DOCS/QUICKSTART.md) (10 min) |
| **Step-by-Step Setup** | [Getting Started Checklist](DOCS/GETTING-STARTED-CHECKLIST.md) |
| **Learn the Codebase** | [Learning Guide](DOCS/learn/00-welcome.md) |
| **Solve a Problem** | [How-To Guides](DOCS/how-to/) |
| **Look Up API** | [Reference Docs](DOCS/reference/) |
| **Understand Concepts** | [Explanations](DOCS/explanation/) |

### By Type (Diataxis Framework)

| Type | Location | Purpose |
|------|----------|---------|
| **[Tutorials](DOCS/tutorials/)** | Hands-on lessons | Learn by building |
| **[How-To Guides](DOCS/how-to/)** | Step-by-step recipes | Solve specific problems |
| **[Reference](DOCS/reference/)** | Technical specs | Look up details |
| **[Explanation](DOCS/explanation/)** | Deep dives | Understand why |

### Key Documentation Files

| File | Purpose |
|------|---------|
| [QUICKSTART.md](DOCS/QUICKSTART.md) | Get started in 10 minutes |
| [GETTING-STARTED-CHECKLIST.md](DOCS/GETTING-STARTED-CHECKLIST.md) | Step-by-step setup checklist |
| [TROUBLESHOOTING.md](DOCS/TROUBLESHOOTING.md) | Solve common problems |
| [VERSIONS.md](DOCS/VERSIONS.md) | Version requirements & compatibility |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [ACCESSIBILITY.md](DOCS/ACCESSIBILITY.md) | Accessibility statement |
| [CHANGELOG.md](DOCS/learn/CHANGELOG.md) | Version history |

---

## 🎓 Learning Path

**For new team members or contributors:**

```
1. Quick Start (10 min)
   └─ Get the app running

2. What This App Does (45 min)
   └─ [DOCS/learn/01-overview.md](DOCS/learn/01-overview.md)

3. Architecture Deep Dive (60 min)
   └─ [DOCS/learn/02-architecture.md](DOCS/learn/02-architecture.md)

4. Swift 6 Concurrency (75 min)
   └─ [DOCS/learn/03-swift6.md](DOCS/learn/03-swift6.md)

5. Additional chapters...
   └─ [DOCS/learn/00-welcome.md](DOCS/learn/00-welcome.md)
```

**Estimated total time:** 12 hours (spread over 4 weeks recommended)

---

## 🛠️ CLI Commands

### Basic Commands

```bash
healthsync discover    # Find iOS devices on local network
healthsync scan          # Scan QR code from clipboard
healthsync pair          # Pair with iOS app
healthsync fetch         # Fetch health data
healthsync status        # Check connection status
healthsync types         # List enabled data types
healthsync version       # Show version info
```

### Fetch Examples

```bash
# Fetch last week's steps as CSV
healthsync fetch --types steps --start 2026-01-01 --end 2026-01-07 > steps.csv

# Fetch multiple types as JSON
healthsync fetch --types steps,heartRate --format json | jq '.samples'

# Fetch with date range
healthsync fetch --start "2026-01-01T00:00:00Z" --end "2026-01-07T23:59:59Z"
```

**Full reference:** [CLI Command Reference](DOCS/learn/09-cli.md)

---

## 🔒 Security

### Local-Only Design

**Data stays on your devices:**
- ✅ No cloud storage
- ✅ No third-party servers
- ✅ No analytics or tracking
- ✅ Bonjour discovery on local network only

### Mutual TLS Authentication

**Certificate-based security:**
1. Both devices generate certificates
2. QR code contains certificate fingerprint
3. Mutual verification on every connection
4. Certificate pinning prevents MITM attacks

**Security details:** [Security Overview](DOCS/learn/07-security.md)

### Local Network Enforcement

The CLI validates hosts are on your local network:
- `localhost`, `127.x.x.x`, `::1`
- Private ranges: `192.168.x.x`, `10.x.x.x`, `172.16-31.x.x`
- Link-local: `fe80::`, `.local` domains

This prevents SSRF attacks.

---

## 📁 Project Structure

```
ai-health-sync-ios/
├── iOS Health Sync App/          # iOS app (Swift 6, SwiftUI)
│   ├── App/                      # App lifecycle & state management
│   ├── Core/                     # Models, DTOs, utilities
│   ├── Features/                 # SwiftUI views
│   └── Services/                 # Business logic (actors)
│       ├── HealthKit/            # Health data access
│       ├── Network/              # HTTP server (TLS)
│       ├── Security/             # Certificates, pairing
│       └── Audit/                # Logging & compliance
│
├── macOS/
│   └── HealthSyncCLI/            # macOS CLI (Swift Package)
│       ├── Sources/              # CLI implementation
│       └── Tests/                # Swift tests (39 tests)
│
├── skills/                       # Agent Skills (agentskills.io)
│   └── healthkit-sync/           # HealthKit sync skill
│       ├── SKILL.md              # Main skill definition
│       └── references/           # CLI, security, architecture docs
│
├── scripts/                      # Build & packaging scripts
│   └── package-clawdhub.sh       # Package skill for ClawdHub
│
├── .github/workflows/            # CI/CD
│   └── release.yml               # Automated release pipeline
│
└── DOCS/                         # Documentation (Diataxis)
    ├── learn/                    # Learning guide
    ├── tutorials/                # Hands-on tutorials
    ├── how-to/                   # Step-by-step guides
    ├── reference/                # API documentation
    └── explanation/              # Deep dives
```

---

## 🧪 Testing

### Run All Tests

```bash
# macOS CLI tests (Swift Package)
cd macOS/HealthSyncCLI
swift test

# iOS app tests
xcodebuild test -project "iOS Health Sync App/iOS Health Sync App.xcodeproj" \
  -scheme "iOS Health Sync App" \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Test Coverage

- **CLI:** 39 tests covering core functionality
- **iOS:** Unit tests for services, UI tests for critical flows

**Testing guide:** [Testing Documentation](DOCS/learn/10-testing.md)

---

## 🤝 Contributing

We welcome contributions! Please see:

- [**CONTRIBUTING.md**](CONTRIBUTING.md) - Contributor guidelines
- [**Good First Issues**](https://github.com/mneves75/ai-health-sync-ios/labels/good%20first%20issue) - Start here
- [**Development Guide**](CONTRIBUTING.md#development-setup) - Setup and workflow

### Quick Contribution Checklist

- [ ] Fork the repository
- [ ] Create a feature branch
- [ ] Make your changes (follow [coding standards](CONTRIBUTING.md#coding-standards))
- [ ] Add/update tests
- [ ] Update documentation
- [ ] Submit pull request

---

## 📋 Version Requirements

### Minimum Versions

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **macOS** | 15 Sequoia | Latest 15 |
| **iOS** | 26.0 | Latest 26 |
| **Xcode** | 26.0 | Latest 26 |
| **Swift** | 6.0 | Latest 6 |

**Full compatibility matrix:** [VERSIONS.md](DOCS/VERSIONS.md)

---

## 🎯 Roadmap

### Version 1.0 (Current)

- ✅ Basic health data sync (steps, heart rate, sleep, workouts)
- ✅ QR code pairing
- ✅ TLS encryption
- ✅ CLI tool
- ✅ Comprehensive documentation

### Version 1.1 (Planned)

- [ ] Blood oxygen support
- [ ] Real-time data streaming
- [ ] Custom data range queries
- [ ] Export to additional formats (JSON, XML)

### Version 2.0 (Future)

- [ ] WatchOS companion app
- [ ] Bi-directional sync (Mac → iPhone)
- [ ] Health Insights dashboard
- [ ] Custom report generation

---

## 📄 License

Licensed under the **Apache License, Version 2.0**.

See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

Built with:
- **Swift 6** - Modern concurrency and safety
- **SwiftUI** - Declarative UI framework
- **SwiftData** - Persistence layer
- **HealthKit** - Apple Health integration
- **Network Framework** - Low-level networking
- **CryptoKit** - Certificate management

---

## 📞 Support

- **Documentation:** [DOCS/](DOCS/)
- **Troubleshooting:** [DOCS/TROUBLESHOOTING.md](DOCS/TROUBLESHOOTING.md)
- **Issues:** [GitHub Issues](https://github.com/mneves75/ai-health-sync-ios/issues)

---

## ⭐ Show Your Support

If you find this project useful:
- ⭐ Star us on GitHub
- 🍴 Fork for your own use
- 🐛 Report bugs or issues
- 📖 Improve documentation
- 💬 Share feedback

---

**iOS Health Sync** - Take control of your health data.

**Last Updated:** 2026-01-07
**Version:** 1.0.0
