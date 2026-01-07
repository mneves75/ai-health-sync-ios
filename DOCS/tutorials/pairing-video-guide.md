# Pairing Video Guide: Connect iPhone and Mac
**Visual walkthrough of the device pairing process**

---

**Time:** 5 minutes
**Difficulty:** Beginner
**Prerequisites:**
- [ ] iOS Health Sync app installed on iPhone
- [ ] macOS CLI (`healthsync`) installed on Mac
- [ ] Both devices on the same WiFi network

---

## Video Demo

Watch the pairing process in action:

**[pairing-demo.mp4](../assets/pairing-demo.mp4)** (749 KB, 18 seconds)

> **Note:** If the video doesn't play in your markdown viewer, open it directly from `DOCS/assets/pairing-demo.mp4`

---

## Step-by-Step Walkthrough

### Step 1: Launch the iOS App

Open **HealthSync** on your iPhone. You'll see the main screen with:

| Section | Initial State |
|---------|---------------|
| **Status** | Version 1.0.0, Protected Data status |
| **HealthKit** | Not Requested |
| **Sharing Server** | Stopped |
| **Pairing** | No QR Code |

```
┌─────────────────────────────────────┐
│           HealthSync                │
│                                     │
│  Status                             │
│  ├── Version: 1.0.0 (1)            │
│  ├── Protected Data: Available     │
│  └── HealthKit: Not Requested      │
│                                     │
│  Permissions                        │
│  └── [Request HealthKit Access]    │
│                                     │
│  Sharing Server                     │
│  ├── Status: Stopped               │
│  └── [Start Sharing]               │
│                                     │
│  Pairing                            │
│  └── No QR Code                    │
│      Start sharing to generate...  │
└─────────────────────────────────────┘
```

---

### Step 2: Request HealthKit Permissions (Optional)

Tap **"Request HealthKit Access"** to authorize the app to read your health data.

**What happens:**
1. iOS shows the HealthKit permission sheet
2. Select which data types to share (steps, heart rate, etc.)
3. Tap "Allow" to grant access

> **Tip:** You can start sharing without HealthKit permissions, but the CLI won't be able to fetch health data until permissions are granted.

---

### Step 3: Start the Sharing Server

Tap **"Start Sharing"** to launch the embedded HTTPS server.

**What changes:**
- Server Status: `Stopped` → `Running`
- IP address and port are displayed
- QR code is generated automatically

```
┌─────────────────────────────────────┐
│  Sharing Server                     │
│  ├── Status: Running               │
│  ├── Address: 192.168.1.100:8443   │
│  └── [Stop Sharing]                │
│                                     │
│  Pairing                            │
│  └── ┌─────────┐                   │
│      │ ▓▓▓▓▓▓▓ │  ← QR Code       │
│      │ ▓▓▓▓▓▓▓ │                   │
│      │ ▓▓▓▓▓▓▓ │                   │
│      └─────────┘                   │
│      Scan with CLI to pair         │
└─────────────────────────────────────┘
```

---

### Step 4: Scan QR Code with Mac CLI

On your Mac, run:

```bash
healthsync scan
```

**What happens:**
1. CLI reads QR code from clipboard (screenshot the QR first)
2. Or use camera: `healthsync scan --camera`
3. Certificates are extracted and stored in Keychain
4. Connection is verified

**Expected output:**
```
Scanning QR code...
✓ Found pairing data
✓ CA certificate valid (expires 2031-01-07)
✓ Client certificate valid (expires 2027-01-07)
✓ Stored in Keychain: healthsync-ca, healthsync-client
✓ Connection verified: https://192.168.1.100:8443
Pairing successful!
```

---

### Step 5: Verify Connection

Test the connection:

```bash
healthsync ping
```

**Expected output:**
```
Pinging https://192.168.1.100:8443...
✓ Response: pong (23ms)
Connection healthy
```

---

### Step 6: Fetch Health Data

Now you can fetch health data:

```bash
healthsync fetch --types steps --start 2026-01-01
```

**Example output:**
```csv
type,value,unit,start_date,end_date,source
steps,8432,count,2026-01-01T00:00:00Z,2026-01-01T23:59:59Z,iPhone
steps,7891,count,2026-01-02T00:00:00Z,2026-01-02T23:59:59Z,iPhone
```

---

## Troubleshooting

### Protected Data: Locked

**Issue:** Server won't start, shows "Protected Data: Locked"

**Solution:** Unlock your iPhone with Face ID/Touch ID/passcode. The Keychain must be accessible to generate certificates.

---

### QR Code Not Appearing

**Issue:** Tapped "Start Sharing" but no QR code

**Possible causes:**
1. Certificate generation failed (check console logs)
2. Network interface not ready

**Solution:**
```bash
# On iPhone: Stop and restart sharing
# Or restart the app
```

---

### CLI Can't Connect

**Issue:** `healthsync ping` times out

**Checklist:**
- [ ] Both devices on same WiFi network?
- [ ] iPhone server showing "Running"?
- [ ] Firewall blocking port 8443?
- [ ] VPN interfering?

**Debug:**
```bash
# Check stored certificates
healthsync status

# Test with verbose output
healthsync ping --verbose
```

---

### Wrong IP Address

**Issue:** CLI connects but gets "Connection refused"

**Solution:** The iPhone's IP may have changed. Re-scan the QR code:
```bash
healthsync unpair
healthsync scan
```

---

## Security Notes

### What the QR Code Contains

The QR code embeds:
- **CA Certificate** (public) - Trust anchor
- **Client Certificate** (public) - Your Mac's identity
- **Client Private Key** - **SENSITIVE** - Only shown once

> **Warning:** Anyone who photographs your QR code can impersonate your Mac. Only display it in private.

### Revoking Access

To unpair devices:

**On Mac:**
```bash
healthsync unpair
```

**On iPhone:**
1. Stop the server
2. Go to Settings → HealthSync → Reset Pairing
3. Or delete and reinstall the app

---

## Video Timestamps

| Time | Action |
|------|--------|
| 0:00-0:05 | Initial state: Server "Stopped", "No QR Code" |
| 0:06-0:10 | Tap "Start Sharing" button |
| 0:10-0:18 | Server running, QR code displayed |

---

## Next Steps

After successful pairing:

1. **[Fetch Steps Data](../how-to/fetch-steps.md)** - Get your first health data
2. **[Export to CSV](../how-to/export-csv.md)** - Save data for analysis
3. **[CLI Reference](../../skills/healthkit-sync/references/CLI-REFERENCE.md)** - All available commands

---

## Related Documentation

- **[Pair Devices](../how-to/pair-devices.md)** - Text-based pairing guide
- **[Security Model](../explanation/security-model.md)** - How mTLS protects your data
- **[Troubleshooting](../TROUBLESHOOTING.md)** - Common issues and solutions

---

*Last updated: 2026-01-07*
