# Fix Pairing Issues: Troubleshoot Device Connection
**Resolve common problems when pairing iPhone and Mac**

---

**Time:** 10-20 minutes
**Difficulty:** Beginner
**Prerequisites:**
- [ ] iOS app installed on iPhone
- [ ] CLI installed on Mac
- [ ] Both devices on same network

---

## Overview

Device pairing uses mTLS (mutual TLS) certificates exchanged via QR code. This guide helps diagnose and fix common pairing failures.

---

## Quick Diagnosis

Run the diagnostic command first:

```bash
healthsync status
```

**Healthy output:**
```
Connection Status: Connected
Server: 192.168.1.100:8443
Certificate: Valid (expires 2027-01-07)
Last sync: 2026-01-07 10:30:00
```

**Problem indicators:**
- `Connection Status: Disconnected` - Network or server issue
- `Certificate: Invalid` or `Expired` - Re-pair required
- `Server: Not configured` - Never paired

---

## Problem: QR Code Won't Scan

### Symptoms
- Camera doesn't recognize QR code
- "Invalid QR code" error
- Scan times out

### Solutions

**1. Check QR code visibility**
```bash
# Ensure QR is fully visible and not cropped
# Hold phone 6-12 inches from screen
# Ensure good lighting (not too bright/dim)
```

**2. Regenerate QR code**

On iOS app:
1. Tap "Stop Sharing"
2. Tap "Start Sharing" again (QR code regenerates automatically)
3. Or tap "Refresh Code" to regenerate without stopping

**3. Use manual entry**

If scanning fails, use clipboard:
1. On iOS: Tap "Copy Connection Info"
2. On Mac:
```bash
healthsync pair --manual
# Paste the connection string when prompted
```

**4. Check camera permissions**

On Mac, ensure Terminal has camera access:
- System Settings → Privacy & Security → Camera → Terminal (enable)

---

## Problem: "Connection Refused" Error

### Symptoms
```
Error: Connection refused to 192.168.1.100:8443
```

### Solutions

**1. Verify server is running**

On iOS app, check status shows "Server Running" with green indicator.

**2. Check firewall settings**

On Mac:
```bash
# Check if port 8443 is blocked
nc -zv 192.168.1.100 8443
```

On iPhone:
- Settings → iOS Health Sync → Allow Local Network (must be ON)

**3. Verify same network**

Both devices must be on the same WiFi network:
```bash
# On Mac, check your IP
ipconfig getifaddr en0

# Should be in same subnet as iPhone (e.g., 192.168.1.x)
```

**4. Disable VPN**

VPNs can block local network traffic:
- Temporarily disable VPN on both devices
- Try pairing again

---

## Problem: "Certificate Validation Failed"

### Symptoms
```
Error: TLS handshake failed - certificate validation error
Error: CERTIFICATE_VERIFY_FAILED
```

### Solutions

**1. Re-pair devices**

Certificates may be corrupted or mismatched:
```bash
# Clear existing certificates
healthsync unpair

# Pair again
healthsync scan
```

**2. Check system time**

Certificate validation requires accurate time:
```bash
# On Mac
date

# If wrong, sync time:
sudo sntp -sS time.apple.com
```

On iPhone: Settings → General → Date & Time → Set Automatically (ON)

**3. Clear Keychain entries**

```bash
# Remove stored certificates
healthsync keychain clear

# Re-pair
healthsync scan
```

---

## Problem: "Server Not Found" on Network

### Symptoms
```
Error: Could not resolve host
Error: No route to host
```

### Solutions

**1. Check iPhone IP address**

On iOS app, the server status shows the IP address. Verify it's reachable:
```bash
ping 192.168.1.100
```

**2. Check for IP change**

iPhone IP may have changed (DHCP lease expired):
1. On iOS app: Stop and restart server
2. Scan new QR code

**3. Check router isolation**

Some routers block device-to-device communication:
- Disable "AP Isolation" or "Client Isolation" in router settings
- Or use a different network

---

## Problem: Pairing Succeeds but Sync Fails

### Symptoms
- QR scan works
- "Paired successfully" message appears
- But `healthsync fetch` fails

### Solutions

**1. Test connection**
```bash
healthsync ping
```

**2. Check HealthKit permissions**

On iPhone:
- Settings → Privacy & Security → Health → iOS Health Sync
- Ensure all required data types are enabled

**3. Check server logs**

On iOS app:
1. Tap "View Logs"
2. Look for error messages during sync attempts

**4. Restart both apps**
```bash
# On Mac
healthsync unpair
healthsync scan

# On iPhone: Force quit and reopen iOS Health Sync app
```

---

## Problem: Intermittent Connection Drops

### Symptoms
- Pairing works initially
- Connection drops after some time
- Need to re-pair frequently

### Solutions

**1. Check WiFi stability**
```bash
# Monitor connection
while true; do healthsync ping; sleep 5; done
```

**2. Disable WiFi power saving**

On iPhone: Settings → WiFi → (i) next to network → Low Data Mode (OFF)

**3. Keep iOS app in foreground**

Background apps have limited network access. Keep app open during sync.

**4. Check for network switching**

Disable "Auto-Join" on other networks to prevent switching:
- Settings → WiFi → Other Networks → Auto-Join (OFF)

---

## Complete Reset Procedure

If nothing else works, perform a complete reset:

### On Mac:
```bash
# 1. Remove all stored data
healthsync unpair
healthsync keychain clear

# 2. Verify clean state
healthsync status
# Should show: "Not configured"
```

### On iPhone:
1. Delete iOS Health Sync app
2. Reinstall from App Store
3. Grant HealthKit permissions again
4. Start server and scan QR code

---

## Diagnostic Commands

```bash
# Full diagnostic report
healthsync diagnose

# Check certificate details
healthsync cert info

# Test network connectivity
healthsync ping --verbose

# View connection logs
healthsync logs --tail 50
```

---

## Getting Help

If issues persist:

1. **Collect diagnostics:**
   ```bash
   healthsync diagnose > ~/Desktop/healthsync-diagnostics.txt
   ```

2. **Check known issues:**
   https://github.com/mneves75/ai-health-sync-ios/issues

3. **Report new issue:**
   ```bash
   gh issue create --repo mneves75/ai-health-sync-ios
   ```

---

## Related Guides

- **[Pair Devices](./pair-devices.md)** - Initial pairing setup
- **[Debug Network](./debug-network.md)** - Network troubleshooting
- **[Generate Certificates](./generate-certificates.md)** - Manual certificate management

---

*Last updated: 2026-01-07*
