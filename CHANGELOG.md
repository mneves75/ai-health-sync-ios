# Changelog

All notable changes to AI Health Sync will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **HealthKit type coverage** — 39 new data types including swimming, cardiac events (irregular rhythm, high/low HR), blood glucose, cycling FTP, hearing exposure, falls, running/cycling/walking dynamics (power, cadence, speed, ground contact, stride length), wrist temperature, AFib burden, time in daylight, and mindful minutes.
- **GPS route export** — `/api/v1/health/routes` endpoint and `healthsync routes` CLI command produce per-workout GPX files via HKWorkoutRoute. Per-route, per-response, and per-workout caps prevent memory exhaustion.
- **Apple Watch exclusives** — `healthsync ecg` and `healthsync hrv-series` commands export ECG voltage waveforms and R-R beat-series with computed SDNN/RMSSD.
- **Structured workout export** — adaptive date-window batching with UUID dedup at boundaries; manifest file with version + counts.
- **FIT binary parser** — pure-Swift parser for the ANT+ FIT format, with Suunto-specific (EPOC, Training Effect, Recovery, FusedSpeed) and Garmin-specific (TSS, Intensity Factor, running dynamics, HRV R-R) field decoders. New `healthsync import --fit` command.
- **Training load model** — `healthsync analyze training-load` computes ATL/CTL/TSB using the standard TrainingPeaks `exp(-1/n)` exponential decay.
- **Anomaly detection** — `healthsync analyze anomalies` flags z-score outliers per type from `healthsync fetch` CSV output.
- **Suunto Sports Tracker integration** — OAuth2 with PKCE, CSRF-protected `state` parameter, and Keychain-backed token storage.
- **Wire-protocol forward compatibility** — `EnabledTypesWire` decodes unknown type strings gracefully and surfaces them as warnings rather than failing.
- **CLI version-skew warning** — `warnVersionSkew` fires from both `status` and `fetch` when the server protocol version isn't in the supported set.
- **Complete HealthKit type coverage** — adds 110 new data types and the full set of 84 documented `HKWorkoutActivityType` cases (verified against Apple's official docs JSON). Categories: 40 nutrition (energy, water, caffeine, all macros, 14 minerals, 13 vitamins), 39 symptoms, 15 reproductive health, 8 lifestyle/event types, 14 vitals/spirometry/mobility (FEV1, FVC, peak expiratory flow, electrodermal activity, walking steadiness, etc.). After this change, `HealthDataType` exposes 178 cases — every fetchable HKSampleType identifier in HealthKit. Previous workout exports labeled most activities as `"other"`; tennis, soccer, hiking, snowboarding, climbing, rowing, dance, and 70+ others now have stable string identifiers.
- **Type categorization** — `HealthDataType.Category` (11 cases) groups the 178 types into Activity & Workouts, Cardiovascular, Body, Sleep, Nutrition, Symptoms, Reproductive Health, Mental Health, Mobility & Hearing, Respiratory & Metabolic, Lifestyle. Each category renders as a collapsible disclosure group in the UI with per-section enabled/total count badges and SF Symbol icons.
- **Sensitive-types policy** — types in reproductive health, mental-health symptoms, alcohol use, and medical-grade cardiac event alerts are flagged via `HealthDataType.isSensitive` and disabled by default. Enabling them requires per-toggle confirmation in the UI; presets that include them prompt for confirmation before applying.
- **Quick-config presets** — `HealthDataType.Preset` provides curated type sets for common personas: General Wellness (default-on baseline), Athlete (activity + cardiovascular + sleep + mobility), Cycle Tracking (reproductive + relevant symptoms + body temp), Health Conditions Monitoring (cardiovascular events + glucose + spirometry).
- **First-launch onboarding** — three-page TabView (welcome → privacy → permission) with Back buttons replaces the previous cold drop into a settings list. Permission page discloses the on-by-default vs sensitive-off-by-default policy.
- **Getting Started checklist** — three-step setup (Grant Health Access → Start Sharing → Pair Your Mac) with live state, progress badge, and footer messaging adapted to current step. Step 3 scrolls to the QR section via ScrollViewReader.
- **HealthKit denial probe** — after authorization, fan-out fetch across 6 common types over 30 days. Tri-state result (`unknown`/`probing`/`granted`/`limited`) drives a "Checking…" status row that flips to "Granted" or "Limited + Open Settings" once the probe resolves. Necessary because iOS hides read-only permission denial.
- **Connected Macs section** — first-class list of paired devices with active state, last-seen relative time, and "Revoke All Pairings" with confirmation dialog. Replaces the previous IA error of putting a security action above the audit log.
- **Typed errors with recovery actions** — `AppError` model with concrete kinds (networkUnavailable, serverPortBusy, certificateFailure, healthKitUnavailable, healthKitDenied, etc.) and Recovery struct (openSettings / openWiFiSettings / retry) routed through `AppErrorRecoveryRunner`. Replaces raw `error.localizedDescription` strings that leaked Network.framework jargon.
- **Audit detail view + filtered log** — tap any audit event to navigate to a parsed-details detail view. Once events exceed 10, "View All N Events" pushes to `AuditLogView` with date grouping (Today / Yesterday / explicit dates) and event-kind filter (Auth / API / Security / Data).
- **Pairing instructions in DisclosureGroup** — three-step pairing guide (`brew install mneves75/tap/healthsync`, `healthsync scan`, "keep this app open") with monospace `textSelection(.enabled)` so the user can long-press to copy. Hidden once a Mac is paired.
- **Live pairing status** — pairing code displays its expiry as a static "Valid until 3:42 PM" with a 30-second TimelineView check that flips to an orange "Expired — tap Refresh" state when the code expires. Code is now copy-on-tap with a `doc.on.doc` icon and accessibility label.
- **Search via `.searchable`** — type picker uses iOS-standard navigation-bar search drawer instead of an inline TextField hack.
- **Quick Presets in toolbar** — wand-and-stars menu in the navigation toolbar instead of a row disguised as data.
- **Privacy policy refresh** — version 1.1, dated April 27 2026; rewritten to disclose the full type surface area, the encrypted-local-only transmission model, the Settings.app revocation path, and the sensitive-categories policy.
- **Unit tests** — 54 new tests covering TrainingLoad EWA convergence, AnomalyDetector statistics, FITParser headers and timestamp arithmetic, HealthSampleMapper for new types, default-on/sensitive-off invariants (no leakage), `Preset.general` round-trip to `defaultEnabled`, and `PairingService.revokeAll` hard-deletion contract.

### Fixed

- **Suunto OAuth port race** — `OAuthCallbackServer` no longer reads `NWListener.port` before the listener reaches `.ready`. Token refresh requests now percent-encode their form bodies. Listener bind failures surface immediately instead of after a 90-second timeout.
- **FIT compressed timestamp rollover** — guards the `0xFFFFFFFF` invalid-value sentinel so it doesn't overflow to epoch 0 and corrupt subsequent records.
- **Training load EWA formula** — switched from the linear `(1 - 1/n)` approximation to the exact `exp(-1/n)` decay (4.4% steady-state correction at 7 TSS/day).
- **Anomaly CSV delimiter** — parser now uses semicolons to match `healthsync fetch --format csv` output.
- **GPS route negative date range** — `handleRoutes` rejects `endDate <= startDate` with 400.
- **GPS route memory cap** — added 100k-point per-response ceiling preventing 500k+ point responses on athletes with many recorded routes.
- **NetworkServer startup race** — `stop()` cancels in-flight `NWListener` and unblocks `start()` waiters with a typed error instead of hanging.
- **ECG / HRV "locked" hint** — error message now correctly references the Apple Watch (not iPhone) since both data sources are Watch-collected.
- **Type enum parity** — iOS app and CLI now share all 60+ HealthKit types; previously each side had ~20 types the other did not.
- **Cardiac event value documentation** — `HKCategorySample.value` encoding documented for cardiac events (`HKCategoryValuePresence`) and `mindfulMinutes` (always `notApplicable`).
- **Manifest write** — `try?` replaced with `try` so encode errors surface instead of being silently dropped.
- **Release CI version guard** — `MARKETING_VERSION` extraction now scopes to the Release config block; empty-string guards prevent silent grep failures from being misinterpreted; the App Store phone number placeholder check blocks accidental release with `REPLACE_WITH_REAL_PHONE_NUMBER`.
- **App Store bundle ID** — corrected in metadata README to match the actual Xcode target identifier.
- **`PairingService.revokeAll` hard-deletes** instead of soft-deleting via `isActive = false`. The previous behavior left revoked devices visible in the Connected Macs section forever and broke the UI's `pairedDevices.isEmpty` reactive gating. Hard delete also removes stale `tokenHash` data on data-minimization grounds.
- **`setEnabledTypes` requests authorization for newly-enabled types** when applying a preset, then re-probes. Previously, presets enabled types the user had never authorized; subsequent fetches silently returned empty samples.
- **`startServer` re-entry guard** prevents `networkServer.start()` being called twice when the user double-taps the Getting Started step 2 row before SwiftUI propagates `isServerStarting`.
- **Typed-error alert and legacy string-error alert no longer race** — the legacy alert is gated on `lastTypedError == nil` so they cannot dismiss each other.
- **`HealthDataType.defaultEnabled` is now derived** from `allCases.filter { !$0.isSensitive }` rather than a hand-curated 10-type list, so adding new non-sensitive types to the enum automatically opts them in.
- **Onboarding page 3 messaging** — accurately describes what's on/off by default after the type expansion (was claiming "10 common metrics" which is no longer true).
- **HealthKit usage description** rewritten to disclose the full type surface area, sensitive opt-in policy, encrypted-local-only transmission, and Settings.app revocation path. Required for App Review §5.1.1(ix).
- **Pairing-code countdown** replaced live per-second ticker with a static "Valid until 3:42 PM" + 30s expiry check. Live ticker created anxiety while the user was mid-pairing on a Mac across the room; static expiry reads as confidence.
- **Audit event icon/color matching** — replaced fragile `String.contains("auth")` (which collided auth and revoke) with exact-match dispatch + category-prefix fallback. Server lifecycle events colored green; generic `api.request` is neutral.
- **Stop Sharing button** demoted from `.borderedProminent + .red tint` (red filled) to a red-text bordered button. Reserves red fills for genuinely destructive actions like Revoke All.
- **Sharing-section running footer** rewritten from scolding ("uses more battery — turn off when you're done") to friendly ("Screen stays on while pairing. You can lock the phone after a Mac connects.")

## [1.0.0] - 2026-02-26

First public release of HealthSync Helper App.

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

### Agent Skills

- **Agent Skills** - [agentskills.io](https://agentskills.io) compatible skill for AI agents
  - `skills/healthkit-sync/SKILL.md` - Main skill with CLI reference and usage patterns
  - `skills/healthkit-sync/references/CLI-REFERENCE.md` - Detailed CLI documentation
  - `skills/healthkit-sync/references/SECURITY.md` - mTLS and certificate pinning patterns
  - `skills/healthkit-sync/references/ARCHITECTURE.md` - Project structure documentation
  - Compatible with ClawdBot, Claude Code, Cursor, Goose, and other Agent Skills tools

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
- **GitHub Actions Hardening** - All actions pinned to SHA hashes per GitHub security guidelines
- **Concurrency Control** - Prevent parallel release workflows
- **Input Validation** - Environment variables used instead of inline expansion (injection prevention)
- **Authorization Header Compatibility** - `Authorization` header parsed case-insensitively, aligning with HTTP semantics
- **Sensitive Log Redaction** - Pairing QR secret (`code`) is no longer written to app logs

### Infrastructure

- **Automated Release Pipeline** - Tag-triggered builds for arm64 and x86_64 binaries
- **Homebrew Tap** - `brew tap mneves75/tap && brew install healthsync`
- **Source Archives** - Each release includes source.zip with SHA256 checksum
- **ClawdHub Publishing** - `scripts/package-clawdhub.sh` for skill packaging

### Reliability

- **NetworkServer Concurrent Startup Guard** - Parallel `start()` calls coordinate through a single startup path, avoiding listener races
- **Startup Cancellation Safety** - `stop()` safely cancels in-flight startup attempts before listener publication

### Documentation

- **Comprehensive Diataxis Documentation** - Tutorials, how-to guides, reference, and explanations
- **Learning Guide** - 10-chapter progressive learning path
- **HOWTO_CLAWDHUB.md** - Step-by-step guide for publishing skills to ClawdHub

### Testing

- **Regression: Authorization Header Casing** - Test coverage for lowercase `authorization` header acceptance
- **Regression: Concurrent Server Start** - Test coverage for concurrent `NetworkServer.start()` calls on fixed ports
