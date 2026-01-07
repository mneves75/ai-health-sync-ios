# Getting Started Checklist

**Step-by-step guide to setting up iOS Health Sync**

---

## ✅ Prerequisites Checklist

Before you begin, make sure you have:

- [ ] **Mac with macOS 15 Sequoia** or later (Apple Silicon required)
- [ ] **Xcode 26** or later ([Download](https://apps.apple.com/app/xcode/id497799835))
- [ ] **iOS 26+** device or simulator
- [ ] **Swift 6** (included with Xcode 26)
- [ ] Both devices on the **same Wi-Fi network**

**Don't have these?** See [Version Requirements](VERSIONS.md) for details.

---

## 🚀 Quick Setup (10 minutes)

### Phase 1: iOS App Setup (5 minutes)

#### Step 1: Clone and Open

- [ ] Clone the repository:
  ```bash
  git clone https://github.com/mneves75/ai-health-sync-ios.git
  cd ai-health-sync-ios-clawdbot
  ```

- [ ] Open the iOS project:
  ```bash
  open "iOS Health Sync App/iOS Health Sync App.xcodeproj"
  ```

#### Step 2: Build and Run

- [ ] Select **iPhone 16** (or your device) in Xcode
- [ ] Press **⌘R** or click **Play** button
- [ ] Wait for build to complete (first build takes longer)

#### Step 3: Verify iOS App

- [ ] App launches successfully
- [ ] You can see the main screen with data type toggles
- [ ] HealthKit authorization prompt appears (first launch only)
- [ ] Authorize health data access when prompted

---

### Phase 2: CLI Companion Setup (5 minutes)

#### Step 4: Build the CLI

- [ ] Navigate to CLI directory:
  ```bash
  cd macOS/HealthSyncCLI
  ```

- [ ] Build using Swift:
  ```bash
  swift build
  ```

- [ ] Verify build succeeded (should see "Build complete!")

#### Step 5: Test CLI Commands

- [ ] Test help command:
  ```bash
  .build/debug/healthsync --help
  ```

- [ ] Test version command:
  ```bash
  .build/debug/healthsync version
  ```

- [ ] Verify output shows version information

---

### Phase 3: First Connection (5 minutes)

#### Step 6: Start iOS Server

- [ ] On iOS app, toggle the data types you want to share
- [ ] Tap **"Start Sharing"** button
- [ ] Note the server port number shown
- [ ] Verify server status shows "Running"

#### Step 7: Discover Device (Optional)

- [ ] On Mac, run:
  ```bash
  cd macOS/HealthSyncCLI
  .build/debug/healthsync discover
  ```

- [ ] Verify your iOS device appears in the list

#### Step 8: Pair Devices (QR code auto-generated)

- [ ] QR code is already visible after starting sharing
- [ ] Tap **"Copy to Clipboard"** to copy pairing data

#### Step 9: Complete Pairing on Mac

- [ ] On Mac, run:
  ```bash
  .build/debug/healthsync scan
  ```

- [ ] Verify pairing success message
- [ ] Server continues running on iOS app

#### Step 10: Test Data Fetch

- [ ] On Mac, run:
  ```bash
  .build/debug/healthsync fetch \
    --start 2026-01-01T00:00:00Z \
    --end 2026-12-31T23:59:59Z \
    --types steps \
    > steps.csv
  ```

- [ ] Open `steps.csv` and verify data was retrieved
- [ ] Check that CSV has headers and data rows

---

## 🎯 Verification Checklist

After completing setup, verify everything works:

### iOS App Verification

- [ ] Can start/stop server successfully
- [ ] Can toggle data types on/off
- [ ] QR code generates correctly
- [ ] Shows paired device(s)
- [ ] No error messages in UI

### CLI Verification

- [ ] Can discover iOS device
- [ ] Shows connection as "Paired"
- [ ] Can fetch health data
- [ ] Output format is correct (CSV/JSON)
- [ ] No error messages in terminal

### Network Verification

- [ ] Both devices on same network
- [ ] Firewall allows local network access
- [ ] Bonjour service discovery works
- [ ] mTLS handshake succeeds

---

## 🔧 Troubleshooting Quick Fixes

### Build Issues

**Problem:** Xcode build fails
- [ ] Check Xcode version is 26+
- [ ] Clean build folder (⇧⌘K)
- [ ] Check Swift version: `swift --version` (must be 6.0+)

**Problem:** CLI build fails
- [ ] Verify Swift is installed: `swift --version`
- [ ] Check you're in the right directory: `macOS/HealthSyncCLI`
- [ ] Run `swift build` (this is a Swift Package, not Node.js)

### Connection Issues

**Problem:** Device not found
- [ ] iOS server is running
- [ ] Both devices on same Wi-Fi
- [ ] Firewall not blocking local network
- [ ] Check with: `dns-sd -B _healthsync._tcp.`

**Problem:** Pairing fails
- [ ] QR code is recent (tokens expire in 5 minutes)
- [ ] Copy fresh QR code from iOS app
- [ ] Check fingerprint matches

### HealthKit Issues

**Problem:** No health data returned
- [ ] HealthKit authorization granted
- [ ] Data types are enabled in iOS app
- [ ] Date range includes today
- [ ] You have actual health data in Health app

---

## 📚 Next Steps

Now that you're set up, explore:

### For Learning
- [ ] Read the [Learning Guide](./learn/00-welcome.md)
- [ ] Study the [Architecture](./reference/architecture.md)
- [ ] Learn about [Security](./learn/07-security.md)

### For Development
- [ ] Review [Contributing Guide](../CONTRIBUTING.md)
- [ ] Check [CLI Reference](./learn/09-cli.md)
- [ ] Explore the [Codebase](../README.md#project-structure)

### For Using
- [ ] Read [How-To Guides](./how-to/README.md)
- [ ] Try [Pairing Devices](./how-to/pair-devices.md)
- [ ] Check [Troubleshooting](./TROUBLESHOOTING.md)

---

## 💡 Pro Tips

### Performance Tips
- Use specific date ranges (not "all time")
- Request only needed data types
- Use JSON format for programmatic access
- Fetch in batches for large date ranges

### Security Tips
- Keep tokens private (don't share QR codes publicly)
- Revoke unused pairings periodically
- Check audit logs regularly
- Update app when new versions are available

### Debugging Tips
- Use `--dry-run` flag to test commands
- Check logs: `log stream --predicate 'subsystem == "org.mvneves"'`
- Run with `--debug-pasteboard` for QR code issues
- Use `status` command to verify connection

---

## ✨ Success Criteria

You've successfully completed setup when:

1. ✅ iOS app runs without errors
2. ✅ CLI builds and responds to commands
3. ✅ Devices are paired (shows in iOS app)
4. ✅ Can fetch health data (CSV/JSON output)
5. ✅ No error messages in either app or terminal

---

## 🆘 Still Stuck?

### Common Issues
- See [Quick Start Troubleshooting](QUICKSTART.md#troubleshooting)
- Check [Full Troubleshooting Guide](TROUBLESHOOTING.md)
- Review [GitHub Issues](https://github.com/mneves75/ai-health-sync-ios/issues)

### Get Help
- 📖 [Browse Documentation](../README.md)
- 💬 [Start a Discussion](https://github.com/mneves75/ai-health-sync-ios/discussions)
- 🐛 [Report a Bug](https://github.com/mneves75/ai-health-sync-ios/issues)

---

**Checklist Version:** 1.0.0
**Last Updated:** 2026-01-07
**Estimated Setup Time:** 15-20 minutes

---

**🎉 Congratulations!** You're all set up with iOS Health Sync.

Ready to explore? Start with [What This App Does](./learn/01-overview.md) or jump to [How-To Guides](./how-to/README.md).
