# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

If you discover a security vulnerability in iOS Health Sync, please report it responsibly:

### How to Report

1. **GitHub Security Advisories (Preferred)**
   - Go to the [Security tab](https://github.com/mneves75/ai-health-sync-ios/security/advisories)
   - Click "Report a vulnerability"
   - Provide detailed information about the issue

2. **Private Disclosure**
   - Open a new issue with the title "Security: [Brief Description]"
   - Mark the issue as confidential if GitHub supports it
   - Or email the maintainer directly with "SECURITY" in the subject

### What to Include

Please provide:

- **Description**: Clear explanation of the vulnerability
- **Impact**: What an attacker could achieve
- **Reproduction Steps**: How to trigger the vulnerability
- **Affected Versions**: Which versions are impacted
- **Suggested Fix**: If you have one (optional)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 1 week
- **Fix Development**: Depends on severity
- **Public Disclosure**: After fix is released

### Severity Levels

| Severity | Response Time | Examples |
|----------|---------------|----------|
| **Critical** | 24-48 hours | Remote code execution, data exfiltration |
| **High** | 1 week | Authentication bypass, privilege escalation |
| **Medium** | 2 weeks | Information disclosure, CSRF |
| **Low** | 1 month | Minor information leaks |

## Security Design

iOS Health Sync is designed with security as a core principle:

### Local-Only Architecture

- **No cloud services** - Data never leaves your local network
- **No analytics** - No tracking or telemetry
- **No external APIs** - All communication is device-to-device

### Encryption

- **TLS 1.3** - All network communication is encrypted
- **mTLS** - Mutual certificate authentication
- **Certificate Pinning** - Prevents MITM attacks

### Data Protection

- **Keychain Storage** - Certificates stored in iOS/macOS Keychain
- **No Persistent Storage** - Health data is not cached to disk
- **Memory-Only** - Sensitive data cleared after use

### Network Security

- **Local Network Validation** - Rejects connections from non-local addresses
- **Pairing Codes** - Time-limited (5 minutes) for replay protection
- **Port Validation** - Validates port ranges (1-65535)

## Security Best Practices for Users

1. **Keep your devices updated** - Use latest iOS and macOS versions
2. **Use secure Wi-Fi** - Avoid public networks for syncing
3. **Verify QR codes** - Only scan codes from your own devices
4. **Monitor pairing** - Revoke access for unknown devices

## Acknowledgments

We appreciate security researchers who help keep iOS Health Sync safe. Contributors who responsibly disclose vulnerabilities will be acknowledged here (with permission).

---

**Last Updated:** 2026-01-07
