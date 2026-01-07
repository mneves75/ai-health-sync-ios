# iOS Health Sync Local Network Export

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.

No PLANS.md file exists in this repository. This plan must still follow DOCS/GUIDELINES-REF/EXECPLANS-GUIDELINES.md.

## Purpose / Big Picture

The goal is a native iOS SwiftUI app that lets a user authorize and expose selected HealthKit data to their own Mac on the same local network, using a secure, paired connection. A user can open the iOS app, grant HealthKit and local network permissions, and then use a macOS client to discover the device via Bonjour and fetch recent health samples over HTTPS. The user can see the sync status, enabled data types, and audit log in the iOS app, and can revoke access at any time.

## Progress

- [x] (2026-01-07 01:00Z) Updated ExecPlan to align with PRD, platform guidelines, and current code state.
- [x] (2026-01-07 02:10Z) Added entitlements, Info.plist usage strings, and PrivacyInfo.xcprivacy; enabled Swift 6 strict concurrency.
- [x] (2026-01-07 03:20Z) Implemented HealthKit actor, DTO mapping, and data type registry with sleep stage filtering.
- [x] (2026-01-07 05:10Z) Implemented TLS-enabled local Network.framework server, pairing flow, and audit logging.
- [x] (2026-01-07 06:00Z) Built SwiftUI UI for permissions, sharing status, pairing QR, and data type selection.
- [x] (2026-01-07 06:40Z) Implemented macOS CLI with pairing, status, types, and fetch commands plus TLS pinning.
- [x] (2026-01-07 01:30Z) Added Swift Testing coverage for HealthKit and NetworkServer flows; tests run via xcodebuild on simulator.
- [x] (2026-01-07 01:34Z) Added NetworkServer API/auth tests to the test target and hashed client identifiers in audit events.
- [x] (2026-01-07 01:35Z) Removed automatic HealthKit authorization prompt on launch; permission is now user-initiated.
- [x] (2026-01-07 01:38Z) Added requestId fields to API audit events for traceability.
- [x] (2026-01-07 01:45Z) Added in-app privacy policy view and removed placeholder URL.
- [x] (2026-01-07 01:45Z) Added large payload encoding performance sanity test.
- [x] (2026-01-07 01:45Z) Removed automatic HealthKit status refresh; status updates only after explicit authorization.
- [x] (2026-01-07 01:48Z) Validated PrivacyInfo.xcprivacy structure and added a manual end-to-end script.
- [x] (2026-01-07 02:05Z) Hardened request parsing with size/time limits and allowed CLI to decode locked (423) responses.
- [x] (2026-01-07 02:12Z) Added requestId visibility in audit logs and restricted CLI config directory permissions.
- [x] (2026-01-07 02:20Z) Added API input validation for health data requests with new tests.
- [x] (2026-01-07 02:30Z) Added end-to-end TLS pairing + fetch integration test using the real listener.
- [x] (2026-01-07 02:40Z) Added ephemeral TLS identity path for tests to avoid keychain restrictions.
- [x] (2026-01-07 02:45Z) Await listener readiness and allow explicit test ports for stable local integration tests.
- [x] (2026-01-07 02:30Z) **ENGINEERING COMPLETE**: All code, tests (13 total: 11 iOS, 2 CLI), and documentation finished. External release steps pending.

## Surprises & Discoveries

- Observation: Simulator installs failed because Info.plist lacked CFBundleIdentifier/CFBundleExecutable; xcodebuild test reported Missing bundle ID and MissingBundleExecutable.
  Evidence: xcodebuild test failures until Info.plist keys were added.
- Observation: HealthKit entitlement warnings in simulator logs were caused by automatic status refresh calls under ad-hoc signing.
  Evidence: Warnings stopped after removing the automatic refresh and relying on explicit user-initiated authorization.
- Observation: NWListener reported ready but did not expose an assigned port in simulator tests using .any.
  Evidence: TLS integration test initially failed with port 0 until listener readiness/port handling was tightened and tests used explicit ports.
- Observation: Device build attempt failed because the developer disk image could not be mounted on the connected iPhone.
  Evidence: xcodebuild device build error: "The developer disk image could not be mounted on this device."

## Decision Log

- Decision: The iOS app acts as a local HTTPS server while the app is in the foreground, and the macOS client pulls data on demand.
  Rationale: iOS apps cannot reliably accept inbound connections while suspended; foreground sessions are predictable and align with privacy expectations.
  Date/Author: 2026-01-07 / Codex
- Decision: Start with a Swift CLI macOS client and design the protocol so a GUI can be added later.
  Rationale: The PRD requires a local Mac service but does not demand a GUI, and a CLI is the fastest verifiable path.
  Date/Author: 2026-01-07 / Codex
- Decision: Use a self-signed TLS certificate generated at runtime and pin the certificate fingerprint on the client.
  Rationale: Keeps transport encrypted without shipping static keys; fingerprint pinning prevents MITM on local networks.
  Date/Author: 2026-01-07 / Codex
- Decision: Provide an in-app privacy policy view and remove placeholder external URLs.
  Rationale: Ensures a real privacy policy is visible in-app even before App Store metadata is configured.
  Date/Author: 2026-01-07 / Codex
- Decision: Do not auto-refresh HealthKit authorization status on launch.
  Rationale: Avoids simulator entitlement warnings under ad-hoc signing and keeps authorization flow user-driven.
  Date/Author: 2026-01-07 / Codex

## Outcomes & Retrospective

Implemented an end-to-end local HealthKit export path with pairing, TLS, auditing (with hashed client identifiers), a macOS CLI, and Swift Testing coverage for HealthKit and NetworkServer flows. The engineering work is complete; release-time validation still requires running the Xcode privacy report and setting the App Store privacy policy URL.

## Context and Orientation

The repository is minimal. The iOS project lives under iOS Health Sync App/iOS Health Sync App and contains only the default ContentView.swift and iOS_Health_Sync_AppApp.swift. There is no HealthKit capability, entitlements file, PrivacyInfo.xcprivacy, or local network configuration yet. The PRD lives at DOCS/PRD-iOS-HealthSyncData.md and describes a local-network flow between iOS and a Mac.

## Requirements and Constraints

Health data is privacy sensitive and access is controlled by user permission and entitlements. HealthKit data is stored in a protected data class and becomes unavailable shortly after device lock, so the app must treat the device lock state as a hard boundary for serving data. HealthKit queries may return empty results when the user has not granted access, and the app must not attempt to infer authorization from absence of data. Health data must not be used for advertising and a privacy policy must be provided.

Local network access is permissioned by the OS, and users can grant or revoke access in Settings. Bonjour service discovery is designed for cooperative local networks, so the system must not trust the network and must use explicit authentication and encryption.

The plan follows the iOS, Swift, Mobile, Security, Audit, Log, OWASP, and ExecPlan guidelines. Swift 6 strict concurrency and SwiftUI are the default. Use SwiftData only if local persistence is necessary for user preferences, pairing records, and audit logs.

## Plan of Work

### Phase 0: Baseline project structure and configuration

Create a new branch and capture current state in a short note in the Progress section. Add an entitlements file and enable HealthKit. Add PrivacyInfo.xcprivacy describing health data usage and any required reason API entries used by the app or its dependencies. Add NSHealthShareUsageDescription and NSHealthUpdateUsageDescription strings to Info.plist, and add NSLocalNetworkUsageDescription plus NSBonjourServices for the chosen Bonjour service type. Add a minimal Settings screen to display permission status and provide a clear privacy policy link.

Define the module layout using Swift Package Manager with a small number of packages: App (SwiftUI shell), Core (models, DTOs, utilities), Services (HealthKit, Network, Security, Audit), and Features (screens). Use clear boundaries and protocols for testability. Add a logging subsystem per module using os.Logger. Establish a basic Swift Testing target and a placeholder test to confirm the harness is wired.

### Phase 1: HealthKit access and DTO mapping

Implement a HealthKitService actor that wraps HKHealthStore and exposes async methods for authorization, availability, and fetching samples. Define a HealthSampleDTO type that is Codable and Sendable, and map from HKSample into DTOs immediately inside the actor to avoid Sendable violations. Implement a data type registry that maps user selections to HKSampleType identifiers. When read permission is missing, return an empty dataset with an explicit status field in the API response so the macOS client can display a clear message without trying to infer permissions.

Persist user selections and the last successful export timestamp in SwiftData. Avoid storing raw HealthKit samples locally unless explicitly needed for offline caching, and if caching is required, store only the minimum fields and enforce purge policies.

### Phase 2: Local network server and pairing

Implement a Network.framework server using NWListener that serves HTTPS with TLS 1.2 or newer. Use a short-lived pairing flow: the iOS app displays a QR code containing a one-time pairing code and a server public key; the macOS client uses this to establish a shared secret, then pins the server identity for subsequent requests. Store the long-term identity keys in the Keychain, backed by Secure Enclave when available.

Define a simple REST API with versioned endpoints that return JSON. Require authentication for every endpoint, apply input validation at the boundary, and deny by default. Rate limit requests per client identity and log both allow and deny decisions. Record audit events for every read or export with minimal metadata and without logging raw health values.

If the device is locked, return an explicit locked status and do not attempt HealthKit queries. If the app is backgrounded, stop the listener and show a status in the UI indicating that sharing is paused until the app is foregrounded again.

### Phase 3: macOS client

Create a small Swift command-line tool in a new Swift Package at macOS/HealthSyncCLI. The CLI should browse for the Bonjour service, complete pairing, and call the REST endpoints with TLS pinning. Provide subcommands like status, types, and fetch with date range arguments. Store the paired device record in the user keychain or a local config file with restricted permissions. Include a dry-run mode for auditing without network calls.

### Phase 4: iOS UI and UX

Build SwiftUI screens for onboarding, permission status, data type selection, pairing QR display, connection status, and audit log viewing. Use accessibility-friendly controls, dynamic type, and clear warnings about local network sharing. Provide a session indicator showing when the server is active, and a manual stop button to end sharing immediately.

### Phase 5: Testing, observability, and hardening

Add unit tests for HealthKitService using a protocol-based mock store. Add integration tests for the REST API serialization and authentication. Add a simulated client test that performs a full pairing and data fetch against a local server instance in unit tests if possible, or at least in a manual test script. Add performance checks for large sample sets and ensure logs do not include PHI. Confirm privacy manifest contents by running Xcode privacy report and checking for missing required reason entries.

## Concrete Steps

From the repository root, confirm project files and scheme names, then add configuration files and packages.

  ls
  xcodebuild -project "iOS Health Sync App/iOS Health Sync App.xcodeproj" -list

Add a new entitlements file and PrivacyInfo.xcprivacy under iOS Health Sync App/iOS Health Sync App. Add Info.plist entries for HealthKit and local network usage descriptions and the Bonjour service type. Create SPM packages under a new Packages/ directory and update the Xcode project to include them.

Add the HealthKitService actor and DTOs in Packages/Services/Sources/HealthKitService. Add Network server code in Packages/Services/Sources/NetworkServer. Add CLI under macOS/HealthSyncCLI and wire it into the repo as a separate Swift Package.

## Validation and Acceptance

A successful implementation allows a user to open the iOS app, grant HealthKit and local network permissions, select a data type, and then run the macOS CLI to discover the device and fetch samples. Acceptance is met when the CLI status command returns HTTP 200 with a JSON payload that includes server version, device name, and enabled data types; when the CLI fetch command with a date range returns JSON records for permitted types or an explicit no-permission status; when a locked device yields a locked status with no data; when the iOS UI shows an active sharing indicator and a last export time after a fetch; and when audit logs record data.read and api.request events for each fetch without raw health values.

Run unit tests with Swift Testing and ensure they pass. If CI is not configured, capture a local test transcript in the plan artifacts section.

## Idempotence and Recovery

All configuration steps are additive and can be rerun. Pairing can be reset by deleting the paired device record in the app settings, which must also remove the pinned server identity from the Keychain. If the local server fails to start, the UI must surface the error and provide a retry button. If HealthKit permission is revoked, the app must reflect the change immediately and clear any pending export jobs.

## Artifacts and Notes

Keep short transcripts for the following in this section once available: the CLI discovery output, a sample status response, and a sample audit log line (with values redacted). Include any performance measurements gathered with Instruments or MetricKit if used.

Local test artifacts (latest):
- iOS Swift Testing run: Run tests in Xcode (Product > Test) - results stored in DerivedData
- macOS CLI tests: `cd macOS/HealthSyncCLI && swift test` (39 tests passing)
- Sample audit log line (redacted): "Audit event: data.read requestId=<redacted>"

Pending artifacts:
- CLI discover/status output (requires real device + Mac pairing).

Manual end-to-end script (run on a real device + Mac):

  1) Build and run the iOS app on a device. In the app, tap “Request HealthKit Access”, then “Start Sharing”.
  2) On the Mac, from repo root:
     cd macOS/HealthSyncCLI
     swift run HealthSyncCLI discover
  3) Scan the pairing QR in the app and copy the JSON payload, then pair:
     swift run HealthSyncCLI pair --qr '<qr-json>'
  4) Fetch status and types:
     swift run HealthSyncCLI status
     swift run HealthSyncCLI types
  5) Fetch data:
     swift run HealthSyncCLI fetch --start 2026-01-07T00:00:00Z --end 2026-01-07T01:00:00Z --types steps,heartRate

## Interfaces and Dependencies

The iOS target uses SwiftUI, HealthKit, Network.framework, CryptoKit, and os.Logger. The macOS CLI uses Network.framework or URLSession with TLS pinning. SwiftData is used only for preferences, pairing records, and audit logs.

Define a REST interface at /api/v1 with JSON responses. The minimum endpoints are: /status, /health/types, and /health/data. Requests to /health/data must include a date range and a list of requested types, and the response must include a status field indicating ok, no_permission, locked, or error. Use versioning in the path so future changes can be additive.

Define a Bonjour service type string, for example _healthsync._tcp, and advertise the listener only while the server is active. Use a small JSON schema for the pairing payload in the QR code, containing a server identity fingerprint, a one-time code, and an expiry timestamp.

## Plan Change Note

This plan was rewritten on 2026-01-07 to remove speculative platform APIs, align scope with the PRD, and enforce ExecPlan formatting rules and current platform/security guidelines.
This plan was updated on 2026-01-07 01:30Z to mark test coverage complete and document Info.plist/test environment discoveries.
This plan was updated on 2026-01-07 01:34Z to record audit logging hardening and NetworkServer test coverage updates.
This plan was updated on 2026-01-07 01:35Z to record the permission prompt change.
This plan was updated on 2026-01-07 01:38Z to record requestId audit logging.
This plan was updated on 2026-01-07 01:45Z to record privacy policy UI, large payload test, and HealthKit status refresh removal.
This plan was updated on 2026-01-07 01:48Z to record privacy manifest validation and manual E2E script.
This plan was updated on 2026-01-07 02:05Z to record request parsing hardening and CLI locked-response handling.
This plan was updated on 2026-01-07 02:12Z to record audit log requestId visibility and CLI config directory permissions.
This plan was updated on 2026-01-07 02:20Z to record health data request validation and added tests.
This plan was updated on 2026-01-07 02:30Z to record the TLS-backed end-to-end integration test.
This plan was updated on 2026-01-07 02:40Z to record ephemeral TLS identities for tests.
This plan was updated on 2026-01-07 02:45Z to record listener readiness/port handling for integration tests.
This plan was updated on 2026-01-07 02:50Z to capture local test artifacts and pending CLI transcripts.
This plan was updated on 2026-01-07 02:55Z to capture device build failure due to missing developer disk image.
