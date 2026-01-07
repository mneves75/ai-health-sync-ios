# Changelog

All notable changes to AI Health Sync will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security

- **GitHub Actions Hardening** - All actions pinned to SHA hashes per GitHub security guidelines
- **Concurrency Control** - Prevent parallel release workflows
- **Input Validation** - Environment variables used instead of inline expansion (injection prevention)

### Infrastructure

- **Automated Release Pipeline** - Tag-triggered builds for arm64 and x86_64 binaries
- **Homebrew Tap** - `brew tap mneves75/tap && brew install healthsync`
- **Source Archives** - Each release includes source.zip with SHA256 checksum
- **ClawdHub Publishing** - `scripts/package-clawdhub.sh` for skill packaging

### Documentation

- **HOWTO_CLAWDHUB.md** - Step-by-step guide for publishing skills to ClawdHub
- **Updated skills/README.md** - ClawdHub section with installation instructions

## [1.0.0] - 2026-01-07

First public release of AI Health Sync.

### Agent Skills

- **Agent Skills** - [agentskills.io](https://agentskills.io) compatible skill for AI agents
  - `skills/healthkit-sync/SKILL.md` - Main skill with CLI reference and usage patterns
  - `skills/healthkit-sync/references/CLI-REFERENCE.md` - Detailed CLI documentation
  - `skills/healthkit-sync/references/SECURITY.md` - mTLS and certificate pinning patterns
  - `skills/healthkit-sync/references/ARCHITECTURE.md` - Project structure documentation
  - Compatible with ClawdBot, Claude Code, Cursor, Goose, and other Agent Skills tools

### iOS App

- **iOS 26 Liquid Glass UI** - Complete design following Apple's Liquid Glass design language
  - `GlassEffectContainer` with morphing transitions between button states
  - `.glassEffect()` and `.buttonStyle(.glassProminent)` modifiers
  - Animated symbol effects (`.symbolEffect(.variableColor)`)
- **Haptic Feedback** - Type-safe `HapticFeedback` helper with `@MainActor` for Swift 6 concurrency
- **HealthKit Integration** - Access steps, heart rate, sleep, workouts, and more
- **Local TLS Server** - Secure communication with macOS CLI
- **QR Code Pairing** - Copy/Share QR code with certificate fingerprint
- **Self-signed Certificates** - Keychain storage with Secure Enclave when available
- **Universal Clipboard** - Copy button syncs JSON payload to macOS via iCloud
- **Background sharing grace period** - Best-effort background task to keep sharing alive briefly when the app backgrounds

### macOS CLI (HealthSyncCLI)

- **CSV Default Output** - `--format csv` is now the default (semicolon separator for spreadsheets)
- **JSON Output** - `--format json` outputs machine-parseable JSON (pipeable to `jq`)
- **Discover Command** - Automatic device discovery via Bonjour/mDNS
  - Uses modern Network framework (NWBrowser) for reliable service discovery
  - `--auto-scan` flag to automatically scan QR from clipboard after discovery
- **Scan Command** - QR code scanning from clipboard or file
  - Text-first detection: Checks for JSON payload in clipboard before image scanning
  - Uses macOS Vision framework for reliable QR image detection
  - Support for `--file <path>` option to scan from image file
- **Pair Command** - Manual pairing with host/port/code/fingerprint
- **Fetch Command** - Retrieve health data with date range and type filters
- **Status Command** - Check connection status
- **Types Command** - List enabled data types
- **Version Command** - `version`, `--version`, `-v` commands with SemVer display
- **Keychain Storage** - Persistent authentication token storage
- **Test Suite** - 39 comprehensive tests

### Security

- **SSRF Protection** - Validates hosts are on local network only
- **Certificate Pinning** - SHA256 fingerprint verification on every connection
- **Pairing Code Expiration** - Time-limited codes prevent replay attacks
- **Port Range Validation** - (1-65535)
- **Local Network Validation**:
  - localhost, IPv4/IPv6 loopback
  - Private IPv4 ranges (10.x, 172.16-31.x, 192.168.x)
  - IPv6 link-local (fe80::)
  - mDNS/Bonjour (.local domains)
