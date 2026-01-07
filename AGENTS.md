# Repository Guidelines

## Project Structure & Module Organization
- `iOS Health Sync App/` contains the SwiftUI iOS app, with feature views under `Features/`, core models under `Core/`, and services under `Services/`.
- `iOS Health Sync App/iOS Health Sync AppTests/` holds iOS app tests using Swift Testing (`@Test`).
- `macOS/HealthSyncCLI/` is a SwiftPM package for the macOS CLI, with sources in `Sources/HealthSyncCLI/` and tests in `Tests/`.
- `DOCS/` contains user and architecture documentation.
- `skills/` holds agent skills and reference docs.

## Build, Test, and Development Commands
- `cd "iOS Health Sync App" && xcodebuild -project "iOS Health Sync App.xcodeproj" -scheme "iOS Health Sync App"`: build iOS app.
- `cd macOS/HealthSyncCLI && swift build`: build the CLI.
- `cd macOS/HealthSyncCLI && swift test`: run CLI unit tests.
- `cd "iOS Health Sync App" && xcodebuild test -scheme "iOS Health Sync App"`: run iOS tests (requires simulator).

## Coding Style & Naming Conventions
- Swift 4‑space indentation, standard Swift API design guidelines.
- Types in UpperCamelCase; methods and variables in lowerCamelCase.
- Keep files named after primary types (`QRCodeView.swift`, `PairingClipboard.swift`).

## Testing Guidelines
- Frameworks: Swift Testing (`@Test`) for both iOS app and CLI.
- Prefer pure function tests for data formatting/validation; avoid UI‑only tests when possible.
- Test naming: short, behavior‑focused names (`extractsPayloadFromDataProvider`).

## Commit & Pull Request Guidelines
- Commits follow Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `perf:`, optionally with scopes (e.g., `fix(cli): ...`).
- PRs should include: a clear summary, testing notes, and screenshots for UI changes.
- Link relevant issues and call out any security‑sensitive changes (QR payloads, clipboard handling).

## Security & Configuration Tips
- QR pairing payloads are sensitive; avoid sharing raw JSON outside the local workflow.
- Ensure devices are on the same LAN and Handoff/Universal Clipboard is enabled for clipboard pairing.
