# Security Model: Understanding iOS Health Sync's Zero-Trust Architecture
**A conceptual guide to how iOS Health Sync protects your health data**

---

## The Problem We're Solving

Your health data is deeply personal. Step counts reveal your activity patterns. Heart rate data shows stress levels. Sleep data exposes your daily rhythm. This information should never leave your control.

Most health sync solutions require:
- Cloud accounts
- Internet connectivity
- Trusting third-party servers
- Accepting privacy policies

iOS Health Sync takes a different approach: **your data never leaves your local network**.

---

## The Zero-Trust Principle

"Zero trust" means we assume nothing is safe by default:

1. **No implicit trust** - Every connection must prove its identity
2. **No cloud dependency** - Works entirely offline
3. **No stored data** - Health data is queried on-demand, not cached
4. **No third parties** - Direct device-to-device communication

Even on your home network, devices must cryptographically prove they're authorized.

---

## How Authentication Works

### The Pairing Ceremony

Think of pairing like exchanging secret handshakes:

```
┌─────────────────────────────────────────────────────────────┐
│                     PAIRING PROCESS                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  iPhone                              Mac                    │
│  ────────                            ────                   │
│                                                             │
│  1. Generate CA certificate                                 │
│     (the "trust anchor")                                    │
│           │                                                 │
│           ▼                                                 │
│  2. Generate server certificate                             │
│     (signed by CA)                                          │
│           │                                                 │
│           ▼                                                 │
│  3. Generate client certificate ──────────────────────────► │
│     (signed by CA)              QR Code contains:           │
│                                 • CA cert (public)          │
│                                 • Client cert (public)      │
│                                 • Client key (private)      │
│                                          │                  │
│                                          ▼                  │
│                                 4. Mac stores certificates  │
│                                    in Keychain              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

After pairing:
- Both devices share the same CA certificate
- iPhone has the server certificate
- Mac has the client certificate
- Each device has only its own private key

---

## Mutual TLS (mTLS) Explained

Regular HTTPS (like visiting a website) only verifies the server:

```
Browser ──────────────────► Website
         "Show me your ID"

Website ──────────────────► Browser
         "Here's my certificate"

Browser: "OK, I trust you"
```

With mTLS, **both sides** must prove identity:

```
Mac CLI ──────────────────► iPhone App
         "Show me your ID"

iPhone ───────────────────► Mac CLI
         "Here's my server certificate"

Mac CLI: "Valid! Signed by our CA"

iPhone ───────────────────► Mac CLI
         "Now show ME your ID"

Mac CLI ──────────────────► iPhone
         "Here's my client certificate"

iPhone: "Valid! Signed by our CA"

Both: "We trust each other. Let's talk."
```

If either certificate is:
- Missing
- Expired
- Signed by a different CA
- Tampered with

...the connection is **rejected**.

---

## Why This Matters

### Scenario 1: Attacker on Your Network

Someone connects to your WiFi and tries to intercept health data.

**Without mTLS:**
```
Attacker pretends to be your Mac
iPhone sends health data to attacker
```

**With mTLS:**
```
Attacker pretends to be your Mac
iPhone: "Show me your certificate"
Attacker: "Uh... here's a fake one?"
iPhone: "Not signed by my CA. Connection refused."
Data stays safe.
```

### Scenario 2: Stolen Mac

Someone steals your Mac and tries to access your health data.

**Protection:**
```
Thief runs: healthsync fetch
CLI attempts connection
iPhone: "Certificate expired" (if you revoked it)
OR
Keychain: "Authenticate to access certificate"
Thief: Doesn't know your Mac password
Data stays safe.
```

### Scenario 3: Malicious App

A malicious app on your Mac tries to impersonate the CLI.

**Protection:**
```
Malicious app tries to connect
iPhone: "Show certificate"
Malicious app: Can't access Keychain without user approval
macOS: "MaliciousApp wants to access 'healthsync-client' in Keychain"
User: Denies access
Data stays safe.
```

---

## The Certificate Chain of Trust

Certificates form a chain, like a family tree:

```
        ┌─────────────────┐
        │ CA Certificate  │  ← The "root of trust"
        │ (Self-signed)   │    Created during first pairing
        └────────┬────────┘    Valid for 5 years
                 │
                 │ signs
                 │
        ┌────────┴────────┐
        │                 │
┌───────▼───────┐ ┌───────▼───────┐
│    Server     │ │    Client     │
│  Certificate  │ │  Certificate  │
│   (iPhone)    │ │    (Mac)      │
└───────────────┘ └───────────────┘
   Valid 1 year     Valid 1 year
```

**Why this works:**
1. CA certificate is the single source of trust
2. Server and client certificates are signed by CA
3. Both devices can verify any certificate against the CA
4. Compromising one certificate doesn't compromise others

---

## Data Flow Security

Here's what happens when you fetch health data:

```
┌─────────────────────────────────────────────────────────────┐
│                    SECURE DATA FLOW                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Mac CLI                             iPhone App             │
│  ────────                            ──────────             │
│                                                             │
│  1. "I want steps data"                                     │
│           │                                                 │
│           │ Encrypted with TLS 1.3                          │
│           │ Client certificate attached                     │
│           ▼                                                 │
│                                      2. Validate certificate│
│                                         ✓ Signed by CA      │
│                                         ✓ Not expired       │
│                                         ✓ Not revoked       │
│                                                │            │
│                                                ▼            │
│                                      3. Query HealthKit     │
│                                         (on-demand)         │
│                                                │            │
│                                                ▼            │
│                                      4. Format response     │
│           ◄──────────────────────────────────────           │
│           │ Encrypted with TLS 1.3                          │
│           │ Server certificate verified                     │
│           ▼                                                 │
│  5. Decrypt and display                                     │
│     (or save to file)                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Key points:**
- Data is encrypted in transit (TLS 1.3)
- Server doesn't store health data
- Data is queried fresh from HealthKit each time
- You control where data goes (display, file, etc.)

---

## What We Don't Protect Against

Being honest about limitations:

### Device Compromise
If someone has full access to your unlocked iPhone or Mac, they can access anything you can access. This is true for any app.

**Mitigation:** Use strong device passcodes, Face ID/Touch ID, and don't leave devices unlocked.

### Physical QR Code Capture
If someone photographs your QR code during pairing, they get the client certificate.

**Mitigation:**
- Only display QR code in private
- QR code is one-time use (re-pairing generates new certificates)
- Unpair to revoke compromised certificates

### Local Network Attacks
If an attacker controls your router, they could potentially block or delay connections (but not read encrypted data).

**Mitigation:** Use trusted networks, consider a dedicated IoT network.

---

## Privacy by Design

iOS Health Sync follows privacy-by-design principles:

| Principle | Implementation |
|-----------|----------------|
| Data minimization | Only requested types are fetched |
| Purpose limitation | Data only used for sync, nothing else |
| Storage limitation | Server stores nothing; you control local storage |
| No tracking | No analytics, telemetry, or fingerprinting |
| Transparency | Open source, auditable code |

---

## Comparison with Alternatives

| Feature | iOS Health Sync | Cloud Sync Services |
|---------|-----------------|---------------------|
| Data location | Your devices only | Third-party servers |
| Internet required | No | Yes |
| Account required | No | Yes |
| End-to-end encrypted | Yes (mTLS) | Sometimes |
| You control keys | Yes | Rarely |
| Open source | Yes | Rarely |
| Works offline | Yes | No |

---

## Key Takeaways

1. **Your data stays local** - Never touches the internet
2. **Both devices authenticate** - mTLS ensures mutual trust
3. **Certificates are device-bound** - Stored securely in Keychain
4. **Nothing is cached** - Health data queried fresh each time
5. **You're in control** - Revoke access anytime by unpairing

---

## Learn More

- **[Security Reference](../reference/security.md)** - Technical specifications
- **[Generate Certificates](../how-to/generate-certificates.md)** - Manual certificate management
- **[Fix Auth Errors](../how-to/fix-auth-errors.md)** - Troubleshooting authentication

---

*Last updated: 2026-01-07*
