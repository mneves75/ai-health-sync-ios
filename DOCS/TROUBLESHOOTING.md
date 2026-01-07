# Troubleshooting Guide

**Solve Common Problems Fast**

---

## 🔍 Quick Diagnosis

**Find your problem by symptom:**

| Symptom | Section |
|---------|---------|
| App won't build | [Build Errors](#build-errors) |
| App crashes on launch | [Launch Issues](#launch-issues) |
| Can't see health data | [HealthKit Issues](#healthkit-issues) |
| Devices won't pair | [Pairing Problems](#pairing-problems) |
| Can't discover device | [Discovery Issues](#discovery-issues) |
| Data sync fails | [Sync Issues](#sync-issues) |
| CLI commands fail | [CLI Issues](#cli-issues) |
| Certificate errors | [Security Issues](#security-issues) |
| Slow performance | [Performance Issues](#performance-issues) |

---

## 🛠️ Build Errors

### Error: "No such module 'SwiftData'"

**Cause:** SwiftData framework not linked or iOS version too old.

**Solution:**
```bash
# 1. Check iOS deployment target
grep -r "IPHONEOS_DEPLOYMENT_TARGET" "iOS Health Sync App.xcodeproj"

# 2. Must be 17.0 or higher
# If lower, update in project settings:
# iOS Health Sync App → TARGETS → General → Minimum Deployments → iOS 17.0
```

**Verification:**
```bash
# Should show iOS 17.0+
xcodebuild -project "iOS Health Sync App.xcodeproj" -showBuildSettings | grep IPHONEOS_DEPLOYMENT_TARGET
```

---

### Error: "Command CompileSwift failed"

**Cause:** Swift compiler error, usually syntax or type issue.

**Solution:**
1. **Check full error message** in Xcode build log
2. **Clean build folder:** `⇧⌘K` in Xcode
3. **Check Swift version:** Must be Swift 6.0+
   ```bash
   swift --version
   ```

4. **Verify Xcode version:** Must be Xcode 26+
   ```bash
   xcodebuild -version
   ```

---

### Error: "Code signing error"

**Cause:** Missing or expired code signing certificates.

**Solution:**
1. **Open Xcode Preferences:**
   - `Xcode` → `Settings` → `Accounts`
   - Ensure Apple ID is signed in

2. **Update Signing:**
   - Select project in Navigator
   - `TARGETS` → `Signing & Capabilities`
   - Check "Automatically manage signing"

3. **For physical devices:**
   - Enable Developer Mode on device
   - Settings → Privacy & Security → Developer Mode

---

## 🚀 Launch Issues

### App Crashes Immediately on Launch

**Cause:** Missing Info.plist keys or entitlements.

**Solution:**
1. **Check HealthKit entitlement:**
   ```xml
   <!-- In iOS Health Sync App/Entitlements -->
   <key>com.apple.developer.healthkit</key>
   <true/>
   ```

2. **Check Info.plist descriptions:**
   ```xml
   <key>NSHealthShareUsageDescription</key>
   <string>This app needs access to your health data to sync with your Mac.</string>

   <key>NSHealthUpdateUsageDescription</key>
   <string>This app needs permission to write health data.</string>

   <key>NSLocalNetworkUsageDescription</key>
   <string>This app uses local network to discover and sync with your Mac.</string>
   ```

3. **Check crash logs:**
   ```bash
   # In Xcode: Window → Devices and Simulators → View Device Logs
   # Or via Terminal:
   log stream --predicate 'subsystem == "com.apple.healthkit"' --level debug
   ```

---

### App Shows "Server Failed to Start"

**Cause:** Port already in use or permission denied.

**Solution:**
1. **Check port availability:**
   ```bash
   lsof -i :8080  # Check default port 8080
   ```

2. **Kill conflicting process:**
   ```bash
   kill -9 <PID from above>
   ```

3. **Check Local Network permission:**
   - iOS Settings → Privacy → Local Network
   - Enable "iOS Health Sync"

4. **Try different port:**
   ```swift
   // In AppState.swift, modify:
   serverPort = 8081  // Use port 8081 instead
   ```

---

## 🏥 HealthKit Issues

### Error: "Authorization Not Determined"

**Cause:** HealthKit authorization not requested or denied.

**Solution:**
1. **Check authorization request in code:**
   ```swift
   // In HealthKitService.swift
   func requestAuthorization(for types: [HealthDataType]) async throws -> Bool {
       let healthTypes = Set(types.compactMap { $0.sampleType })
       try await healthStore.requestAuthorization(toShare: [], read: healthTypes)
   }
   ```

2. **Request authorization on app launch:**
   ```swift
   // In iOS_Health_Sync_AppApp.swift
   .task {
       await appState.requestHealthAuthorization()
   }
   ```

3. **Manual permission grant:**
   - iOS Settings → Health → Data Access & Devices
   - Find "iOS Health Sync"
   - Enable all desired data types

---

### No Health Data Returned

**Cause:** No data in HealthKit or wrong date range.

**Solution:**
1. **Add sample data to HealthKit:**
   - Open Health app on device/simulator
   - Browse → Health Data → Steps
   - Add Data → Enter steps for today

2. **Check date range in query:**
   ```swift
   // Ensure date range includes today
   let startDate = Calendar.current.startOfDay(for: Date())
   let endDate = Date()
   ```

3. **Verify data type mapping:**
   ```swift
   // Check HealthDataType enum has correct HKSampleType
   case .steps:
       return HKQuantityType(.stepCount)
   ```

---

### Error: "Type Not Available on This Device"

**Cause:** Health data type not supported on device/simulator.

**Solution:**
1. **Check device capabilities:**
   ```swift
   let healthStore = HKHealthStore()
   if healthStore.isHealthDataAvailable() {
       // HealthKit is available
   }
   ```

2. **Verify data type availability:**
   ```swift
   if #available(iOS 17.0, *) {
       // Use new API
   } else {
       // Fallback
   }
   ```

3. **Use physical device instead of simulator:**
   - Some data types not available in simulator
   - Test on real device

---

## 🔗 Pairing Problems

### QR Code Won't Scan

**Cause:** QR code expired, malformed, or camera issue.

**Solution:**
1. **Generate fresh QR code:**
   - iOS app → Show QR Code
   - Wait for regeneration (5 min expiration)

2. **Check QR code quality:**
   - Ensure good lighting
   - Hold camera steady
   - Fill screen with QR code

3. **Manual pairing (alternative):**
   ```bash
   # Copy pairing token manually
   healthsync pair --token <token-from-ios-app>
   ```

---

### Pairing Timeout

**Cause:** Network timeout or certificate generation slow.

**Solution:**
1. **Check network connectivity:**
   ```bash
   ping -c 3 <iOS-device-ip>
   ```

2. **Increase timeout:**
   ```swift
   // In PairingService.swift
   const pairingTimeout: TimeInterval = 30  // Increase from 10 to 30 seconds
   ```

3. **Retry pairing:**
   - Generate new QR code
   - Clear previous pairing attempt
   - Try again

---

### "Certificate Verification Failed"

**Cause:** Certificate mismatch or man-in-the-middle attack.

**Solution:**
1. **Verify certificate fingerprint:**
   ```bash
   # Check iOS app shows correct fingerprint
   # Compare with CLI output
   healthsync status
   ```

2. **Clear stored certificates:**
   ```swift
   // Delete from Keychain
   KeychainStore.shared.delete(key: "pairingCertificate")
   ```

3. **Re-pair from scratch:**
   - Delete app data
   - Uninstall and reinstall
   - Generate new pairing

---

## 🔍 Discovery Issues

### CLI Can't Find iOS Device

**Cause:** Bonjour service not registered or network issue.

**Solution:**
1. **Verify iOS server running:**
   - Check "Start Sharing" was tapped
   - Look for "Server Running" status

2. **Check same network:**
   - Both devices on same Wi-Fi
   - No VPN or firewall blocking

3. **Test Bonjour manually:**
   ```bash
   # Browse for HealthKit services
   dns-sd -B _healthsync._tcp local.

   # Should show:
   # Browsing for _healthsync._tcp local.
   # timestamp: ...
   # Add 1 0 0 ... iOS Health Sync._healthsync._tcp. local.
   ```

4. **Check firewall:**
   ```bash
   # Ensure port 8080 is open
   sudo pfctl -s rules | grep 8080
   ```

---

### "Device Found But Connection Refused"

**Cause:** Server not listening or wrong port.

**Solution:**
1. **Check server status in iOS app:**
   - Look for "Status: Running"
   - Note the port number (default: 8080)

2. **Test connection manually:**
   ```bash
   # Try HTTP request
   curl http://<iOS-ip>:8080/api/v1/status

   # Should return JSON with status
   ```

3. **Restart iOS server:**
   - Stop Server
   - Start Server again
   - Verify new port

---

## 📡 Sync Issues

### Health Data Fetch Returns Empty

**Cause:** No data in range or query error.

**Solution:**
1. **Check date range:**
   ```bash
   # Verify date range includes data
   healthsync fetch --start yesterday --end now
   ```

2. **Add test data:**
   - Use Health app to add steps/heart rate
   - Ensure data is in query range

3. **Check enabled data types:**
   ```bash
   healthsync types
   # Should show enabled types
   ```

4. **Enable debug logging:**
   ```swift
   // In NetworkServer.swift, enable:
   os_log("API request: %@", log: .network, request.description)
   ```

---

### "Rate Limit Exceeded"

**Cause:** Too many requests in short time.

**Solution:**
1. **Wait for rate limit reset:**
   - Default: 60 requests per minute
   - Wait 60 seconds before retrying

2. **Adjust rate limit (development only):**
   ```swift
   // In NetworkServer.swift
   private let rateLimitWindow: TimeInterval = 60  // 1 minute
   private let maxRequestsPerWindow: Int = 120     // Increase from 60
   ```

3. **Implement backoff:**
   ```bash
   # Use --wait flag for batch operations
   healthsync fetch --wait 2  # Wait 2 seconds between requests
   ```

---

## 💻 CLI Issues

### "Command Not Found: healthsync"

**Cause:** CLI not built or not in PATH.

**Solution:**
1. **Build CLI (Swift Package):**
   ```bash
   cd macOS/HealthSyncCLI
   swift build
   ```

2. **Add to PATH:**
   ```bash
   # Add to shell profile (~/.zshrc or ~/.bash_profile)
   export PATH="$PATH:$HOME/dev/ai-health-sync-ios/macOS/HealthSyncCLI/.build/debug"

   # Reload shell
   source ~/.zshrc
   ```

3. **Or use absolute path:**
   ```bash
   .build/debug/healthsync discover
   ```

---

### Swift Build Fails

**Cause:** Swift not installed or version mismatch.

**Solution:**
1. **Install Xcode (includes Swift):**
   ```bash
   xcode-select --install
   ```

2. **Verify Swift version:**
   ```bash
   swift --version  # Should be 6.0+
   ```

3. **Clean and retry:**
   ```bash
   swift package clean
   swift build
   ```

---

## 🔒 Security Issues

### "mTLS Handshake Failed"

**Cause:** Certificate expired or mismatched.

**Solution:**
1. **Check certificate expiration:**
   ```swift
   // In CertificateService.swift
   let cert = SecCertificateCreateWithData(nil, certData)
   // Check expiration date
   ```

2. **Regenerate certificates:**
   ```bash
   # Clear Keychain
   security delete-generic-password -s "healthsync-cert"

   # Re-pair devices
   ```

3. **Verify certificate chain:**
   ```bash
   openssl s_client -connect localhost:8080 -showcerts
   ```

---

### Keychain Access Denied

**Cause:** Keychain permission or locked.

**Solution:**
1. **Unlock Keychain:**
   ```bash
   security unlock-keychain ~/Library/Keychains/login.keychain-db
   ```

2. **Add Keychain entitlements:**
   ```xml
   <!-- In Entitlements -->
   <key>keychain-access-groups</key>
   <array>
       <string>$(AppIdentifierPrefix)org.mvneves.healthsync</string>
   </array>
   ```

3. **Reset Keychain item:**
   ```swift
   KeychainStore.shared.delete(key: "pairingToken")
   ```

---

## ⚡ Performance Issues

### App Uses Too Much Memory

**Cause:** Memory leak or large data retained.

**Solution:**
1. **Profile with Instruments:**
   - Xcode → Product → Profile
   - Choose "Leaks" or "Allocations"
   - Identify leaks

2. **Check for retain cycles:**
   ```swift
   // Use [weak self] in closures
   Task { [weak self] in
       await self?.fetchData()
   }
   ```

3. **Limit query results:**
   ```swift
   // Add limit to HealthKit queries
   let query = HKSampleQuery(sampleType, predicate: 1000, ...)  // Max 1000 results
   ```

---

### Slow Data Fetch

**Cause:** Too much data or inefficient queries.

**Solution:**
1. **Add pagination:**
   ```swift
   // Use offset and limit
   let response = await fetchSamples(
       types: [.steps],
       startDate: startDate,
       endDate: endDate,
       limit: 100,
       offset: page * 100
   )
   ```

2. **Query specific date ranges:**
   ```swift
   // Don't query all time
   let startDate = Date().addingTimeInterval(-7 * 24 * 3600)  // Last 7 days only
   ```

3. **Use background tasks:**
   ```swift
   Task.detached(priority: .background) {
       await fetchLargeDataSet()
   }
   ```

---

## 🐛 Debug Mode

### Enable Debug Logging

**iOS App:**
```swift
// In main.swift or AppDelegate
#if DEBUG
os_log(.default, log: OSLog(subsystem: "com.healthsync", category: "debug"), "Debug mode enabled")
#endif
```

**CLI:**
```bash
# Enable verbose output
healthsync discover --verbose
healthsync fetch --debug
```

### View Console Logs

**iOS Simulator:**
```bash
log stream --predicate 'subsystem == "org.mvneves.healthsync"' --level debug
```

**Xcode Console:**
1. Run app from Xcode
2. View console output at bottom
3. Filter by "HealthSync"

### Network Debugging

**Capture HTTP traffic:**
```bash
# Use tcpdump
sudo tcpdump -i any -n port 8080

# Or use Wireshark for GUI
```

**Check TLS handshake:**
```bash
openssl s_client -connect <iOS-ip>:8080 -showcerts
```

---

## 📊 Diagnostic Information

### Generate Diagnostic Report

**iOS App:**
1. Long press on server status in app
2. Select "Generate Diagnostic Report"
3. Report includes:
   - App version
   - Server status
   - Last errors
   - Device capabilities
   - Certificate info

**CLI:**
```bash
healthsync status
# Outputs:
# - Connection status
# - Paired device info
# - Certificate validity
```

---

## 🆘 Still Need Help?

### Check System Status

- GitHub Issues: [https://github.com/mneves75/ai-health-sync-ios/issues](https://github.com/mneves75/ai-health-sync-ios/issues)
- Discussions: [https://github.com/mneves75/ai-health-sync-ios/discussions](https://github.com/mneves75/ai-health-sync-ios/discussions)

### Report a Bug

When reporting, include:
1. **OS and versions:**
   ```bash
   sw_vers          # macOS version
   xcodebuild -version  # Xcode version
   swift --version       # Swift version
   ```

2. **Error message:** Full error text

3. **Steps to reproduce:** What you did before the error

4. **Expected behavior:** What should happen

5. **Actual behavior:** What actually happened

6. **Logs:** Console output or crash logs

---

## 📚 Related Documentation

- [Quick Start Guide](QUICKSTART.md)
- [Architecture Reference](./reference/architecture.md)
- [HealthKit Guide](./learn/06-healthkit.md)
- [Security Overview](./learn/07-security.md)
- [Contributing Guide](../CONTRIBUTING.md)

---

**Last Updated:** 2026-01-07
**Troubleshooting Version:** 1.0.0
