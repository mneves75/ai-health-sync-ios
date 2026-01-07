# How To Use AI Health Sync

A step-by-step guide to syncing your Apple HealthKit data from iPhone to Mac.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Setting Up the iOS App](#setting-up-the-ios-app)
3. [Building the macOS CLI](#building-the-macos-cli)
4. [Discovering Devices](#discovering-devices)
5. [Pairing Your Devices](#pairing-your-devices)
6. [Syncing Health Data](#syncing-health-data)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware
- iPhone with HealthKit data (iPhone 8 or later recommended)
- Mac with Apple Silicon or Intel processor
- Both devices on the **same local network** (Wi-Fi)

### Software
- **iOS**: iOS 17.0 or later
- **macOS**: macOS 14.0 (Sonoma) or later
- **Xcode**: 15.0 or later (for building from source)
- **Swift**: 6.0 or later

### HealthKit Permissions
The iOS app requires HealthKit permissions to read your health data. You'll be prompted to grant access when you first launch the app.

---

## Setting Up the iOS App

### Step 1: Open the Project in Xcode

```bash
cd ai-health-sync-ios
open "iOS Health Sync App/iOS Health Sync App.xcodeproj"
```

### Step 2: Configure Signing

1. Select the project in Xcode's navigator
2. Go to **Signing & Capabilities**
3. Select your **Team** (personal or organization)
4. Ensure **HealthKit** capability is enabled

### Step 3: Build and Run

1. Connect your iPhone via USB or select it from the device list
2. Press **Cmd + R** or click the Run button
3. Trust the developer certificate on your iPhone if prompted:
   - Go to **Settings > General > VPN & Device Management**
   - Tap your developer certificate and tap **Trust**

### Step 4: Grant HealthKit Access

When the app launches:
1. Tap **Allow** when prompted for HealthKit access
2. Select which health data types you want to sync
3. Tap **Done**

---

## Building the macOS CLI

### Option A: Build from Source

```bash
# Navigate to the CLI directory
cd macOS/HealthSyncCLI

# Build release version
swift build -c release

# Verify it works
.build/release/healthsync help
```

### Option B: Install System-Wide

```bash
# Build and copy to /usr/local/bin
cd macOS/HealthSyncCLI
swift build -c release
sudo cp .build/release/healthsync /usr/local/bin/

# Now you can run from anywhere
healthsync help
```

### Verify Installation

```bash
healthsync help
```

You should see:
```
HealthSync CLI - Sync health data from iOS

USAGE: healthsync <command> [options]

COMMANDS:
  discover  Find iOS devices on local network (Bonjour/mDNS)
  scan      Scan QR code from clipboard or file for pairing
  pair      Pair with iOS app
  sync      Sync health data from paired device
  status    Show pairing and connection status
  help      Show this help
```

---

## Discovering Devices

Before pairing, you can verify your iPhone is visible on the network:

```bash
healthsync discover
```

**Expected output:**
```
Searching for HealthSync devices on local network...
Found 1 device(s):

  iPhone
    Host: 192.168.1.100
    Port: 53271

Use 'healthsync scan' with the QR code to pair.
```

### Streamlined Workflow with --auto-scan

You can combine discovery and QR scanning in one command:

1. Screenshot the QR code to clipboard (Cmd+Ctrl+Shift+4)
2. Run:
   ```bash
   healthsync discover --auto-scan
   ```

This will discover devices AND automatically scan the QR code from your clipboard.

If no devices are found, see [Troubleshooting](#no-devices-found-with-discover).

---

## Pairing Your Devices

Pairing connects your Mac to your iPhone securely. You only need to do this once.

### Method 1: QR Code Scan (Recommended)

**On your iPhone:**
1. Open AI Health Sync
2. Tap **Show Pairing QR Code**
3. A QR code will appear with a 5-minute expiration timer

**On your Mac:**
1. Take a screenshot of the QR code (or use your phone to show it)
2. If screenshot is in clipboard:
   ```bash
   healthsync scan
   ```
3. If screenshot is saved as a file:
   ```bash
   healthsync scan --file ~/Desktop/qr-code.png
   ```

**Expected output:**
```
✓ QR code detected
✓ Host validated (192.168.1.100)
✓ Certificate fingerprint verified
✓ Pairing successful!

Device paired: iPhone (192.168.1.100:8443)
Token stored in Keychain
```

### Method 2: Manual Pairing

If QR scanning doesn't work, you can pair manually:

**On your iPhone:**
1. Open AI Health Sync
2. Tap **Show Pairing Details**
3. Note the Host, Port, Code, and Fingerprint values

**On your Mac:**
```bash
healthsync pair \
  --host 192.168.1.100 \
  --port 8443 \
  --code ABC123 \
  --fingerprint "sha256:abcd1234..." \
  --name "My MacBook"
```

---

## Syncing Health Data

Once paired, syncing is simple:

### Basic Sync

```bash
healthsync sync
```

This retrieves all available health data from your iPhone.

### Check Status

```bash
healthsync status
```

Shows:
- Paired device information
- Connection status
- Last sync time

---

## Troubleshooting

### No Devices Found with Discover

**Cause:** The `discover` command uses Bonjour/mDNS to find iOS devices on your local network.

**Solutions:**
1. Ensure the iOS app is running and showing "Status: Running"
2. Both devices must be on the **same Wi-Fi network**
3. Check that no firewall is blocking mDNS/Bonjour (UDP port 5353)
4. Try disabling VPN if connected
5. On some networks, mDNS traffic is blocked between devices (common in corporate/hotel WiFi)

**Alternative:** If discovery doesn't work, you can still pair using the QR code scan method.

### "Host must be on local network"

**Cause:** The QR code contains a host that isn't on your local network.

**Solution:**
- Ensure both devices are on the same Wi-Fi network
- Check that your iPhone isn't using cellular data
- Regenerate the QR code on your iPhone

### "Pairing code has expired"

**Cause:** QR codes expire after 5 minutes for security.

**Solution:**
- Generate a new QR code on your iPhone
- Scan it immediately

### "Certificate fingerprint mismatch"

**Cause:** The certificate on the iPhone has changed since pairing.

**Solution:**
- Delete the existing pairing: `healthsync unpair`
- Re-pair using a fresh QR code

### "Connection refused"

**Cause:** The iOS app server isn't running.

**Solution:**
- Open AI Health Sync on your iPhone
- Ensure the app is in the foreground
- Check that the server status shows "Running"

### "No QR code found in image"

**Cause:** The image doesn't contain a readable QR code.

**Solution:**
- Ensure the QR code is fully visible and not cropped
- Try taking a clearer screenshot
- Ensure good lighting if photographing the screen

### QR Code Not Scanning from Clipboard

**macOS clipboard must contain an image.** Try:

```bash
# Take a screenshot to clipboard
# Press Cmd + Ctrl + Shift + 4, select the QR code area

# Then scan
healthsync scan
```

Or save as file:
```bash
# Take screenshot to file
# Press Cmd + Shift + 4, select the QR code area

# Scan the file
healthsync scan --file ~/Desktop/Screenshot*.png
```

### Firewall Blocking Connection

If you have a firewall enabled:

1. **macOS Firewall**: System Settings > Network > Firewall > Options
   - Add `healthsync` to allowed apps

2. **Little Snitch / Lulu**: Allow connections to local network (192.168.x.x, 10.x.x.x)

### Reset Everything

If all else fails, start fresh:

**On Mac:**
```bash
# Remove stored credentials
security delete-generic-password -s "healthsync" 2>/dev/null
```

**On iPhone:**
1. Delete and reinstall the app
2. Re-grant HealthKit permissions

Then pair again using a new QR code.

---

## Security Notes

### Why Local Network Only?

AI Health Sync deliberately restricts connections to local network addresses. This prevents:
- Accidental exposure of health data to the internet
- Malicious QR codes that redirect to attacker servers
- Man-in-the-middle attacks outside your network

### Certificate Pinning

The QR code includes a SHA256 fingerprint of your iPhone's TLS certificate. Every connection verifies this fingerprint, ensuring you're talking to your actual iPhone and not an impostor.

### Data Privacy

- Health data never leaves your local network
- No cloud services or accounts required
- All data is encrypted in transit (TLS 1.3)
- Pairing tokens stored securely in macOS Keychain

---

## Getting Help

If you encounter issues not covered here:

1. Check the [CHANGELOG.md](CHANGELOG.md) for known issues
2. Review the [README.md](README.md) for updates
3. Run with verbose output: `healthsync sync --verbose`
