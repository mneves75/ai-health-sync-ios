# Debug Network: Troubleshoot Connection Issues

**Diagnose and fix network communication problems**

---

**Time:** 15 minutes
**Difficulty:** Intermediate
**Prerequisites:**
- [ ] Basic understanding of networking
- [ ] Terminal access on Mac
- [ ] iOS app running

---

## Goal

Diagnose and resolve network issues between the iOS app and macOS CLI.

---

## Steps

### Step 1: Verify Network Connectivity

**Check both devices are on same network:**

```bash
# On Mac - get IP address
ipconfig getifaddr en0

# On iOS - Settings > Wi-Fi > (i) > IP Address
```

**Ping iOS device from Mac:**

```bash
ping -c 3 <iOS-IP-address>
```

**Expected:** All 3 packets received.

---

### Step 2: Check Server Status

**In iOS app:**
1. Open iOS Health Sync
2. Verify "Status: Running"
3. Note the port number (default: 8080)

**Test HTTP connection:**

```bash
# Basic connectivity test (HTTP)
curl -v http://<iOS-IP>:8080/api/v1/status

# With timeout
curl -v --connect-timeout 5 http://<iOS-IP>:8080/api/v1/status
```

---

### Step 3: Test Bonjour Discovery

**Browse for services:**

```bash
# List all HealthSync services
dns-sd -B _healthsync._tcp local.

# Should output:
# Browsing for _healthsync._tcp local.
# Add 1 0 0 ... iOS Health Sync._healthsync._tcp. local.
```

**Resolve service details:**

```bash
dns-sd -L "iOS Health Sync" _healthsync._tcp local.

# Should show IP address and port
```

---

### Step 4: Check Firewall

**On macOS:**

```bash
# Check if firewall is enabled
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# If enabled, check blocked apps
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --listapps
```

**On iOS:**
- Settings > Privacy & Security > Local Network
- Ensure "iOS Health Sync" is enabled

---

### Step 5: Test TLS Handshake

**Check TLS connection:**

```bash
# Test TLS handshake
openssl s_client -connect <iOS-IP>:8080 -showcerts

# Should show certificate chain
```

**With client certificate (mTLS):**

```bash
openssl s_client -connect <iOS-IP>:8080 \
  -cert ~/client.pem \
  -key ~/client-key.pem \
  -showcerts
```

---

### Step 6: View Network Logs

**iOS Console logs:**

```bash
# Stream logs from iOS device/simulator
log stream --predicate 'subsystem == "org.mvneves.healthsync"' --level debug

# Filter for network events
log stream --predicate 'subsystem == "org.mvneves.healthsync" AND category == "network"'
```

**In Xcode:**
1. Run app from Xcode
2. View Console at bottom
3. Filter by "Network"

---

### Step 7: Capture Network Traffic

**Using tcpdump:**

```bash
# Capture traffic on port 8080
sudo tcpdump -i any -n port 8080

# Save to file for analysis
sudo tcpdump -i any -n port 8080 -w capture.pcap
```

**Using Wireshark:**

1. Open Wireshark
2. Select network interface
3. Filter: `tcp.port == 8080`
4. Start capture

---

### Step 8: Test with Verbose CLI

```bash
# Enable verbose output
healthsync discover --verbose

# Debug connection
healthsync status --debug

# Test with specific IP
healthsync connect --host <iOS-IP> --port 8080 --verbose
```

---

## Verification

**Successful connection shows:**

```bash
healthsync status

# Output:
# Connection Status: Paired
# Device: iPhone 16
# IP: 192.168.1.100:8080
# Secure: Yes (mTLS)
# Latency: 5ms
```

---

## Common Issues

### Issue: "Connection refused"

**Cause:** Server not running or wrong port.

**Solution:**
1. Verify iOS server is running
2. Check port number in iOS app
3. Try: `curl http://<iOS-IP>:8080/`

### Issue: "Connection timeout"

**Cause:** Network unreachable or firewall blocking.

**Solution:**
1. Verify same Wi-Fi network
2. Disable VPN
3. Check firewall settings
4. Try: `ping <iOS-IP>`

### Issue: "TLS handshake failed"

**Cause:** Certificate mismatch or expired.

**Solution:**
1. Unpair devices: `healthsync unpair`
2. Re-pair: `healthsync scan`
3. Verify certificate fingerprints match

### Issue: "Device not found"

**Cause:** Bonjour service not registered.

**Solution:**
1. Restart iOS server
2. Check Local Network permission on iOS
3. Test: `dns-sd -B _healthsync._tcp local.`

### Issue: "mDNS not resolving"

**Cause:** mDNS/Bonjour blocked on network.

**Solution:**
1. Try direct IP connection
2. Check router settings for mDNS
3. Use: `healthsync connect --host <IP>`

---

## Network Requirements

| Protocol | Port | Direction | Purpose |
|----------|------|-----------|---------|
| TCP | 8080 | iOS → Mac | HTTP/HTTPS server |
| UDP | 5353 | Multicast | mDNS/Bonjour |
| TCP | 8080 | Mac → iOS | API requests |

---

## Debug Commands Quick Reference

```bash
# Network discovery
dns-sd -B _healthsync._tcp local.
dns-sd -L "iOS Health Sync" _healthsync._tcp local.

# Connectivity
ping <iOS-IP>
curl -v http://<iOS-IP>:8080/api/v1/status

# TLS
openssl s_client -connect <iOS-IP>:8080 -showcerts

# Traffic capture
sudo tcpdump -i any -n port 8080

# Logs
log stream --predicate 'subsystem == "org.mvneves.healthsync"'

# CLI debug
healthsync discover --verbose
healthsync status --debug
```

---

## Performance Debugging

**Measure latency:**

```bash
# Time a request
time curl http://<iOS-IP>:8080/api/v1/status

# Multiple requests
for i in {1..10}; do
  time curl -s http://<iOS-IP>:8080/api/v1/status > /dev/null
done
```

**Check for packet loss:**

```bash
ping -c 100 <iOS-IP> | tail -2
# Shows packet loss percentage
```

---

## See Also

- [Pair Devices](./pair-devices.md) - Initial pairing
- [Fix Pairing Issues](./fix-pairing.md) - Pairing problems
- [Troubleshooting](../TROUBLESHOOTING.md) - General troubleshooting

---

**Last Updated:** 2026-01-07
