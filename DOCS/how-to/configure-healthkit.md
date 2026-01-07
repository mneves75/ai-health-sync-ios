# Configure HealthKit: Enable Health Data Access

**Set up HealthKit permissions and authorization for the iOS app**

---

**Time:** 10 minutes
**Difficulty:** Beginner
**Prerequisites:**
- [ ] Xcode 26 installed
- [ ] iOS Health Sync project open in Xcode
- [ ] iOS device or simulator running iOS 26+

---

## Goal

Configure HealthKit capabilities and request user authorization to read health data from the iOS Health app.

---

## Steps

### Step 1: Enable HealthKit Capability

1. Open the project in Xcode
2. Select **iOS Health Sync App** in the Project Navigator
3. Select the **iOS Health Sync App** target
4. Go to **Signing & Capabilities** tab
5. Click **+ Capability**
6. Search for **"HealthKit"** and add it

**Expected:** HealthKit appears in the capabilities list with a checkmark.

---

### Step 2: Verify Entitlements

The entitlements file should already be configured. Verify it contains:

```xml
<!-- In HealthSync.entitlements -->
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.healthkit.access</key>
<array/>
```

**Location:** `iOS Health Sync App/Resources/HealthSync.entitlements`

---

### Step 3: Check Info.plist Descriptions

HealthKit requires usage descriptions. Verify these exist in `Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>This app needs access to your health data to sync with your Mac.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>This app may write health data from synced sources.</string>
```

**Important:** iOS will reject apps without these descriptions.

---

### Step 4: Build and Run

1. Select your target device/simulator in Xcode
2. Press **Cmd+R** to build and run
3. App launches on device/simulator

---

### Step 5: Authorize Health Access

When the app first launches:

1. A HealthKit authorization dialog appears
2. Review the requested data types
3. Toggle **ON** the data types you want to share:
   - Steps
   - Heart Rate
   - Sleep Analysis
   - Active Energy
   - etc.
4. Tap **"Allow"**

**Note:** You can modify permissions later in Settings > Health > Data Access & Devices.

---

### Step 6: Verify Authorization

In the app:
1. Check that data type toggles are enabled
2. Start the server
3. If no errors appear, authorization succeeded

**In code (for debugging):**
```swift
let healthStore = HKHealthStore()
let stepType = HKQuantityType(.stepCount)
let status = healthStore.authorizationStatus(for: stepType)

switch status {
case .sharingAuthorized:
    print("Read access granted")
case .notDetermined:
    print("Not yet requested")
case .sharingDenied:
    print("Access denied by user")
@unknown default:
    break
}
```

---

## Verification

**Test health data access:**

```bash
# After pairing, fetch steps from CLI
healthsync fetch --types steps --limit 5
```

**Expected:** Returns step count data (if data exists in HealthKit).

**If empty:** Add test data to Health app first.

---

## Adding Test Data

### On Simulator

1. Open **Health** app in simulator
2. Go to **Browse > Activity > Steps**
3. Tap **"Add Data"**
4. Enter step count and date
5. Tap **"Add"**

### On Physical Device

Use Apple Watch, iPhone motion sensors, or third-party apps to generate real health data.

---

## Common Issues

### Issue: "Authorization dialog doesn't appear"

**Cause:** Authorization already requested (iOS only shows once).

**Solution:**
1. Delete the app from device/simulator
2. Reinstall and run again
3. Or: Settings > Health > Data Access > iOS Health Sync > Reset Authorization

### Issue: "No health data returned"

**Cause:** HealthKit READ permissions can't be verified (Apple privacy).

**Solution:**
- Apple intentionally hides read denial for privacy
- Check write permission status as proxy
- Verify data exists in Health app for the queried date range

### Issue: "HealthKit not available"

**Cause:** Running on unsupported device or simulator without HealthKit.

**Solution:**
```swift
if HKHealthStore.isHealthDataAvailable() {
    // HealthKit is available
} else {
    // Not available (iPad without HealthKit, etc.)
}
```

---

## Data Types Supported

| Data Type | HKQuantityType | Unit |
|-----------|---------------|------|
| Steps | `.stepCount` | count |
| Heart Rate | `.heartRate` | count/min |
| Active Energy | `.activeEnergyBurned` | kcal |
| Distance | `.distanceWalkingRunning` | m |
| Flights Climbed | `.flightsClimbed` | count |
| Sleep | `.sleepAnalysis` | category |
| Blood Oxygen | `.oxygenSaturation` | % |
| Respiratory Rate | `.respiratoryRate` | count/min |

See [HealthKit Guide](../learn/06-healthkit.md) for full list.

---

## Privacy Considerations

**What users should know:**
- Health data never leaves the local network
- All transfers use mTLS encryption
- No cloud storage or third-party access
- Users control which data types are shared

**For developers:**
- Never log PII or health values
- Use AuditService for access logging
- Hash identifiers before logging
- Follow Apple's HealthKit guidelines

---

## See Also

- [HealthKit Guide](../learn/06-healthkit.md) - Deep dive into HealthKit integration
- [Pair Devices](./pair-devices.md) - Connect iPhone and Mac
- [Troubleshooting Auth Errors](./fix-auth-errors.md) - Authorization issues

---

**Last Updated:** 2026-01-07
