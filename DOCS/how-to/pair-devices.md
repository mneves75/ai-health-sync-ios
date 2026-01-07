# Pair Devices: How to Connect iPhone and Mac

**Establish secure device-to-device connection using QR code pairing**

---

**Time:** 5 minutes
**Difficulty:** Beginner
**Prerequisites:**
- [ ] iOS app running on iPhone/simulator
- [ ] macOS CLI built and available
- [ ] Both devices on same network

---

## Goal

Pair your iOS device with your Mac so they can communicate securely using mutual TLS authentication.

---

## Steps

### Step 1: Start the iOS Server

1. Open the iOS Health Sync app
2. Toggle the health data types you want to sync
3. Tap **"Start Server"**
4. Note the server status shows **"Server Running: YES"**

**Expected:** Server status displays green indicator with port number (default: 8080)

---

### Step 2: Generate Pairing QR Code

1. Tap **"Show QR Code"** button
2. Wait for QR code to generate (takes 1-2 seconds)
3. QR code displays with pairing token

**Important:** QR code expires after 5 minutes. If expired, generate a new one.

---

### Step 3: Scan QR Code with CLI

**Option A: Automatic Scan (from clipboard)**

```bash
# On iOS device, copy the QR code text
# Long press QR code → Copy

# On Mac, scan from clipboard
healthsync scan
```

**Option B: Manual Scan (from image)**

```bash
# Take screenshot of QR code on iOS device
# Then scan from image file
healthsync scan --image /path/to/screenshot.png
```

**Option C: Manual Token Entry**

```bash
# Type pairing token manually
healthsync pair --token abc123def456
```

---

### Step 4: Verify Pairing

**On CLI:**
```bash
healthsync status
```

**Expected output:**
```
📡 Connection Status: ✅ Paired
📱 Device: iPhone 16 Simulator
🔒 Secure: Yes (mTLS)
🔐 Fingerprint: SHA256:abc123def456...
📊 Enabled: 27 data types
📦 Version: 1.0.0
```

**On iOS App:**
- Look for **"Paired Devices: 1"** indicator
- Server status should still show **"Running"**

---

## Verification

**Test the connection:**

```bash
# Fetch health data to verify connection works
healthsync fetch --types steps --limit 1
```

**Success:** Data is returned without errors.

**Failure:** See [Troubleshooting](#troubleshooting) below.

---

## Common Issues

### Issue: "Device Not Found"

**Cause:** iOS server not running or not on same network.

**Solution:**
1. Verify iOS server is running
2. Check both devices on same Wi-Fi
3. Disable VPN if enabled
4. Try: `healthsync discover --verbose`

### Issue: "Pairing Token Expired"

**Cause:** QR code older than 5 minutes.

**Solution:**
1. Generate new QR code in iOS app
2. Scan immediately with CLI

### Issue: "Certificate Verification Failed"

**Cause:** Certificate mismatch or corrupted.

**Solution:**
```bash
# Clear stored certificates
healthsync unpair

# Try pairing again
healthsync scan
```

---

## Unpairing Devices

**To remove pairing:**

```bash
# From CLI
healthsync unpair

# Or from iOS app
# Settings → Paired Devices → Select device → Remove
```

---

## Security Notes

**What happens during pairing:**

1. **iOS generates certificate:**
   - Creates private/public key pair
   - Stores in Keychain
   - Shares public certificate via QR code

2. **Mac generates certificate:**
   - Creates its own key pair
   - Stores in local Keychain
   - Sends public certificate to iOS

3. **Mutual verification:**
   - Both devices verify peer certificates
   - mTLS handshake established
   - All further communication encrypted

**Certificate storage:**
- **iOS:** Keychain (protected by device passcode/biometrics)
- **Mac:** User Keychain (protected by system login)

---

## See Also

- [Generate Certificates](./generate-certificates.md) - Manual certificate creation
- [Troubleshooting Pairing](../TROUBLESHOOTING.md#pairing-problems) - Common pairing issues
- [Security Overview](../explanation/security-model.md) - How security works

---

**Last Updated:** 2026-01-07
