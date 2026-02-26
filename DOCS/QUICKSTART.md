# Quick Start Guide

**Get the HealthSync Helper App Running in 10 Minutes**

---

## ⚡ Prerequisites Checklist

Before you begin, ensure you have:

- [ ] **Mac** with macOS 15 Sequoia or later (Apple Silicon required)
- [ ] **Xcode 26** or later ([Download](https://developer.apple.com/xcode/))
- [ ] **iOS 26** Simulator or physical device
- [ ] **Git** installed (`git --version`)
- [ ] ~2GB free disk space

**Don't have these?** See [Full Prerequisites](VERSIONS.md) for detailed setup.

---

## 🚀 10-Minute Setup

### Step 1: Clone the Repository (1 minute)

```bash
git clone https://github.com/mneves75/ai-health-sync-ios.git
cd ai-health-sync-ios
```

### Step 2: Open the iOS Project (1 minute)

```bash
open "iOS Health Sync App/iOS Health Sync App.xcodeproj"
```

### Step 3: Build and Run (3 minutes)

1. Select **iPhone 16** simulator (or your physical device)
2. Press **⌘R** or click the **Play** button
3. Wait for Xcode to build (first build takes longer)
4. App launches on simulator/device

**✅ Success!** You should see the main app screen with sync configuration options.

---

## 📱 First Run: What You'll See

```
┌─────────────────────────────────────┐
│  HealthSync Helper App                     │
├─────────────────────────────────────┤
│  ☑ Steps                             │
│  ☐ Heart Rate                        │
│  ☐ Sleep Analysis                    │
│  ☐ Workouts                          │
│                                      │
│  [Start Server] button               │
│  [Show QR Code] button               │
└─────────────────────────────────────┘
```

**Try this:**
1. Toggle a data type (Steps, Heart Rate, etc.)
2. Tap "Start Sharing"
3. See server status and port number

---

## 💻 Test the macOS CLI (3 minutes)

### Step 4: Build the CLI

The CLI is a Swift Package - build it using Swift:

```bash
cd macOS/HealthSyncCLI
swift build
```

**Expected output:** Swift compilation completes successfully

**⚠️ Important:**
- Use `swift build` NOT `bun install` (this is a Swift package, not a Node.js project)
- Build output goes to `.build/debug/healthsync`
- First build takes 10-30 seconds (subsequent builds are faster)

**Troubleshooting:**
- **"swift: command not found"** → Install Xcode from the App Store (includes Swift)
- **"product 'macOS' is unsupported"** → You need macOS 15 Sequoia or later
- **Build fails with linking errors** → Run `xcode-select --install` and try again

### Step 5: Discover Your iOS Device

```bash
.build/debug/healthsync discover
```

**Expected output:**
```
✅ Found device: iPhone Simulator (192.168.1.100:8080)
📱 Device Name: iPhone 16
🔐 Fingerprint: SHA256:ABC123...
```

**Note:** The iOS app must be running and the server started before discovery works.

### Step 6: Check Connection Status

```bash
.build/debug/healthsync status
```

**Expected output:**
```
📡 Connection Status: Paired
📱 Device: iPhone Simulator
🔒 Secure: Yes (mTLS)
```

---

## ✅ Verify Everything Works

**iOS App Checklist:**
- [ ] App launches without errors
- [ ] Can toggle health data types
- [ ] Can start/stop the server
- [ ] Can show QR code for pairing

**CLI Checklist:**
- [ ] Can discover iOS device
- [ ] Shows connection status
- [ ] No error messages in output

**❌ Something Wrong?** See [Troubleshooting](#troubleshooting) below.

---

## 🎯 What's Next?

**For Learners:**
- Read the [Learning Guide](./learn/00-welcome.md) for comprehensive tutorial
- Start with [Chapter 1: What This App Does](./learn/01-overview.md)

**For Developers:**
- Check [Architecture Overview](./reference/architecture.md)
- See [Contributing Guide](../CONTRIBUTING.md)

**For Users:**
- Read [How-To Guides](./how-to/README.md)
- See [CLI Reference](./learn/09-cli.md)

---

## 🔧 Troubleshooting

<details>
<summary>❌ "Build Failed" Error</summary>

**Problem:** Xcode shows build errors.

**Solutions:**
1. **Check Xcode version:** Must be Xcode 26 or later
   ```bash
   xcodebuild -version
   ```

2. **Clean build folder:**
   - In Xcode: `Product` → `Clean Build Folder` (⇧⌘K)

3. **Check Swift version:**
   ```bash
   swift --version
   # Must be Swift 6.0+
   ```

</details>

<details>
<summary>📡 "Device Not Found" (CLI)</summary>

**Problem:** `healthsync discover` finds nothing.

**Solutions:**
1. **Ensure iOS server is running:**
   - Open iOS app
   - Tap "Start Sharing"
   - Check server status shows "Running"

2. **Check same network:**
   - Both devices on same Wi-Fi
   - Firewall allows local network access

3. **Verify Bonjour service:**
   ```bash
   dns-sd -B _healthsync._tcp.
   ```

</details>

<details>
<summary>🔐 "Authorization Denied" (HealthKit)</summary>

**Problem:** App can't access health data.

**Solutions:**
1. **Check Info.plist:** Ensure `NSHealthShareUsageDescription` exists
2. **Re-request authorization:**
   - iOS Settings → Health → Data Access & Devices
   - Find "HealthSync Helper App"
   - Enable all data types
3. **Delete and reinstall app** (last resort)

</details>

<details>
<summary>🔗 "Pairing Failed"</summary>

**Problem:** QR code scan doesn't work.

**Solutions:**
1. **Generate new QR code:**
   - iOS app → Show QR Code
   - Wait for new code to generate

2. **Check token expiration:**
   - Tokens expire after 5 minutes
   - Generate fresh QR code

3. **Verify certificates:**
   - Check Keychain for stored certificates
   - Clear and retry pairing

</details>

### More Help?

- **Full Troubleshooting Guide:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **GitHub Issues:** [Report a problem](https://github.com/mneves75/ai-health-sync-ios/issues)
- **Discussions:** [Ask questions](https://github.com/mneves75/ai-health-sync-ios/discussions)

---

## 📊 Version Compatibility

| Component | Minimum Version | Recommended Version |
|-----------|-----------------|---------------------|
| macOS | 15 Sequoia | Latest |
| Xcode | 26.0 | Latest |
| iOS | 26.0 | Latest |
| Swift | 6.0 | Latest |
| HealthKit | iOS 8+ | N/A |
| SwiftData | iOS 17+ | N/A |

---

## 🎓 Learning Path

**Complete Beginner?** Start here:

1. ⏱️ **Now** (10 min) - Complete this Quick Start
2. ⏱️ **Today** (1 hour) - Read [What This App Does](./learn/01-overview.md)
3. ⏱️ **Week 1** - Complete [Learning Guide Chapters 1-3](./learn/00-welcome.md)
4. ⏱️ **Week 2** - Build your first feature

**Already Know iOS/Swift?** Jump to:

- [Architecture Reference](./reference/architecture.md)
- [Security Overview](./learn/07-security.md)
- [Contributing Guide](../CONTRIBUTING.md)

---

## ⚡ Keyboard Shortcuts (Xcode)

| Shortcut | Action |
|----------|--------|
| ⌘R | Build and Run |
| ⌘. | Stop |
| ⇧⌘K | Clean Build Folder |
| ⌘B | Build |
| ⌘⇧Y | Debug Area |
| ⌘0 | Show Standard Editor |

---

## 📝 Next Steps

You've successfully set up the HealthSync Helper App! Here's what to do next:

### For Learning
```
Quick Start ✅ → Learning Guide → Build Your First Feature
                      ↓
                [learn/](./learn/)
```

### For Development
```
Quick Start ✅ → Architecture → Contributing Guide → Contribute
                      ↓              ↓
                [reference/](./reference/)  [CONTRIBUTING.md](../CONTRIBUTING.md)
```

### For Using
```
Quick Start ✅ → How-To Guides → Reference
                      ↓            ↓
                [how-to/](./how-to/)  [reference/](./reference/)
```

---

**✨ You're ready to go!** The app is running and you can explore the codebase.

**Need help?** See [Full Documentation](../README.md) or [GitHub Discussions](https://github.com/mneves75/ai-health-sync-ios/discussions)

---

**Estimated Time to Complete:** 10 minutes

**Last Updated:** 2026-01-07

**Quick Start Version:** 1.0.1

---

## 💡 Feedback

**Was this Quick Start helpful?**

Your feedback helps improve this guide for everyone.

- 👍 **Yes, it was helpful!** → [Tell us what worked](https://github.com/mneves75/ai-health-sync-ios/issues/new?title=%5BDOC%5D+Positive+Feedback&labels=documentation,feedback&body=##+What+was+helpful%3F%0A%0AThe+Quick+Start+guide+was...)
- 👎 **No, it needs work** → [Tell us what to fix](https://github.com/mneves75/ai-health-sync-ios/issues/new?title=%5BDOC%5D+QuickStart+Feedback&labels=documentation,feedback&body=##+What+needs+improvement%3F%0A%0AI+got+stuck+on...)
- ✏️ **Improve this page** → [Edit on GitHub](https://github.com/mneves75/ai-health-sync-ios/edit/main/DOCS/QUICKSTART.md)

### Need Help?

- 📖 Check our [Troubleshooting Guide](./TROUBLESHOOTING.md)
- 📚 Browse [all documentation](./README.md)
- 💬 Start a [Discussion](https://github.com/mneves75/ai-health-sync-ios/discussions)
