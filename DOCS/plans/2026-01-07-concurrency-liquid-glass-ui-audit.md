# Exec Spec: Concurrency + Liquid Glass + UI Patterns Hardening

## Context
The iOS app adopts iOS 26 Liquid Glass and Swift concurrency. A targeted review surfaced:
- Liquid Glass usage without availability gating or interactive glass on tappable controls.
- A QR code render race in `QRCodeView` that can display stale images under rapid updates.
- A listener start race in `NetworkServer` where `.ready` can be missed if state handlers attach after start.

## Goals
- Ensure Liquid Glass is correct, interactive, and safe on pre‑iOS 26.
- Prevent stale QR renders with deterministic task cancellation/token checks.
- Make server start readiness robust against fast listener state transitions.
- Add tests that validate the new behaviors.

## Non‑Goals
- Redesign UI/visual language beyond Liquid Glass correctness.
- Expand networking protocols or change API behavior.

## Phase 1 — Design & API Decisions
- Decide on Liquid Glass fallbacks for pre‑iOS 26:
  - Buttons: `.bordered` / `.borderedProminent` with matching tints.
  - Glass surfaces: `.background(.ultraThinMaterial, in: shape)`.
  - Glass container: passthrough `HStack`/`Group` when glass is unavailable.
- Define a `QRCodeViewModel` to manage background rendering with task cancellation and tokens.
- Refactor `NetworkServer.awaitReady` to install the handler before starting the listener.

## Phase 2 — Implementation
- Liquid Glass
  - Add a small helper for availability‑gated button styles and glass surfaces.
  - Apply `.interactive()` on tappable glass surfaces and consistent shapes.
  - Use the helper in `ContentView` for all glass usage.
- QR rendering
  - Introduce `QRCodeViewModel` with token + cancellation.
  - Update `QRCodeView` to delegate rendering to the model.
- NetworkServer start
  - Move `listener.start(queue:)` into `awaitReady` so handlers attach first.

## Phase 3 — Tests
- Add unit tests for `QRCodeViewModel`:
  - Latest payload wins when renders overlap.
  - Task cancellation does not update image.
- Add test for `NetworkServer.start()` readiness behavior:
  - Start/stop cycle sets `snapshot.port` and does not time out.

## Phase 4 — Verification
- Run iOS app tests with `xcodebuild test`.
- Re-scan for Liquid Glass usage to confirm all call sites are gated.

## Acceptance Criteria
- No Liquid Glass API usage without `#available(iOS 26, *)`.
- Tappable glass controls use interactive glass or glass button styles.
- QR rendering never publishes a stale image.
- NetworkServer reliably reaches ready state without missing the signal.
- Tests covering new behavior pass.
