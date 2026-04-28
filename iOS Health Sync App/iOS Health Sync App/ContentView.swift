// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - ContentView

/// Main application view redesigned for iOS 26 Liquid Glass design language.
/// Glass effects are applied to the navigation/control layer while content remains below.
struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \AuditEventRecord.timestamp, order: .reverse) private var auditEvents: [AuditEventRecord]
    @State private var typeSearch: String = ""
    @State private var expandedCategories: Set<HealthDataType.Category> = Set(
        HealthDataType.Category.allCases.filter { $0.defaultExpanded }
    )
    @State private var showSensitiveConfirmation: HealthDataType.Preset?

    @Query private var pairedDevices: [PairedDevice]

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    if shouldShowGettingStarted {
                        gettingStartedSection(scrollProxy: proxy)
                    }
                    serverSection
                    pairingSection
                        .id("pairingSection")
                    if hasPairedDevice {
                        connectedMacsSection
                    }
                    // Data types shown as soon as the user has granted Health
                    // access — they need to be able to see and adjust what
                    // will be shared *before* pairing, not after.
                    if appState.healthAuthorizationStatus {
                        dataTypesSection
                        manualExportSection
                    }
                    auditSection
                    settingsSection
                }
                .listStyle(.insetGrouped)
                .sheet(isPresented: $showingManualExport) {
                    ManualExportView()
                        .environment(appState)
                }
            }
            .navigationTitle("HealthSync")
            .searchable(
                text: $typeSearch,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: appState.healthAuthorizationStatus ? "Search categories" : ""
            )
            .toolbar {
                if appState.healthAuthorizationStatus {
                    ToolbarItem(placement: .topBarTrailing) {
                        presetMenuToolbar
                    }
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            appState.handleScenePhaseChange(newPhase)
        }
        // Single alert chain — typed errors take precedence over the legacy
        // string error. The legacy alert only fires when there is no typed
        // error pending so they cannot dismiss each other.
        .alert(item: typedErrorBinding) { error in
            errorAlert(for: error)
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { appState.lastTypedError == nil && appState.lastError != nil },
                set: { if !$0 { appState.lastError = nil } }
            )
        ) {
            Button("OK") { appState.lastError = nil }
        } message: {
            Text(appState.lastError ?? "")
        }
    }

    private var typedErrorBinding: Binding<IdentifiableAppError?> {
        Binding(
            get: { appState.lastTypedError.map(IdentifiableAppError.init) },
            set: { if $0 == nil { appState.lastTypedError = nil } }
        )
    }

    /// Builds the typed-error Alert with optional recovery action. NOT
    /// `@ViewBuilder` — `Alert` is its own value type, not a `View`, so the
    /// function must return it explicitly via `return` statements.
    private func errorAlert(for error: IdentifiableAppError) -> Alert {
        let recovery = error.appError.recovery
        if let recovery {
            return Alert(
                title: Text(error.appError.title),
                message: Text(error.appError.message),
                primaryButton: .default(Text(recovery.label)) {
                    AppErrorRecoveryRunner.run(recovery)
                    appState.lastTypedError = nil
                },
                secondaryButton: .cancel(Text("Cancel")) {
                    appState.lastTypedError = nil
                }
            )
        } else {
            return Alert(
                title: Text(error.appError.title),
                message: Text(error.appError.message),
                dismissButton: .default(Text("OK")) {
                    appState.lastTypedError = nil
                }
            )
        }
    }

    /// App version from bundle (matches AboutView)
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    /// Shows the Getting Started section until the user has paired at least
    /// one Mac. After first successful pair we hide it permanently — toggling
    /// the server off later should not bring the onboarding checklist back.
    private var shouldShowGettingStarted: Bool {
        pairedDevices.isEmpty
    }

    private var hasPairedDevice: Bool { !pairedDevices.isEmpty }

    /// Step-by-step setup checklist for non-technical users. Each row reflects
    /// the actual state of the app and dims when complete.
    private func gettingStartedSection(scrollProxy: ScrollViewProxy) -> some View {
        Section {
            stepRow(
                number: 1,
                title: "Grant Health Access",
                detail: "Allows HealthSync to read your Apple Health data.",
                isComplete: appState.healthAuthorizationStatus,
                isActionable: !appState.healthAuthorizationStatus
            ) {
                HapticFeedback.impact(.medium)
                Task { await appState.requestHealthAuthorization() }
            }

            // Inline warning if the probe found no data despite the user
            // granting access. iOS hides denial for read-only, so this is the
            // only signal we have to surface a likely "actually denied" state.
            if appState.healthAuthorizationStatus,
               appState.healthDataProbeState == .limited {
                limitedAccessWarningRow
            }

            stepRow(
                number: 2,
                title: "Start Sharing",
                detail: "Turns on the connection so a Mac can fetch your data.",
                isComplete: appState.isServerRunning,
                isActionable: appState.healthAuthorizationStatus
                    && !appState.isServerRunning
                    && !appState.isServerStarting
            ) {
                HapticFeedback.impact(.medium)
                Task { await appState.startServer() }
            }

            stepRow(
                number: 3,
                title: "Pair Your Mac",
                detail: "Install HealthSync CLI on your Mac via Homebrew, then run \u{201C}healthsync scan\u{201D} to pair using the QR code below.",
                isComplete: hasPairedDevice,
                isActionable: appState.isServerRunning && !hasPairedDevice,
                actionLabel: hasPairedDevice ? nil : "Scroll to QR code"
            ) {
                HapticFeedback.selection()
                withAnimation {
                    scrollProxy.scrollTo("pairingSection", anchor: .top)
                }
            }
        } header: {
            HStack {
                Image(systemName: "checklist")
                Text("Getting Started")
                Spacer()
                Text(setupProgress)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        } footer: {
            if !appState.healthAuthorizationStatus {
                Text("Tap step 1 to begin. The whole setup takes under a minute.")
                    .font(.caption)
            } else if !appState.isServerRunning {
                Text("Tap step 2 to turn on sharing.")
                    .font(.caption)
            } else if !hasPairedDevice {
                Text("On your Mac, run the HealthSync CLI to pair. Instructions below the QR code.")
                    .font(.caption)
            } else {
                Text("Setup complete. Your Mac is paired.")
                    .font(.caption)
            }
        }
    }

    private var setupProgress: String {
        var done = 0
        if appState.healthAuthorizationStatus { done += 1 }
        if appState.isServerRunning { done += 1 }
        if hasPairedDevice { done += 1 }
        return "\(done) of 3"
    }

    @ScaledMetric(relativeTo: .body) private var stepBadgeSize: CGFloat = 28

    @ViewBuilder
    private func stepRow(
        number: Int,
        title: String,
        detail: String,
        isComplete: Bool,
        isActionable: Bool,
        actionLabel: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isComplete ? Color.green : (isActionable ? Color.accentColor : Color.secondary.opacity(0.25)))
                        .frame(width: stepBadgeSize, height: stepBadgeSize)
                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.callout.weight(.bold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(number)")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isComplete ? .secondary : .primary)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if isActionable, let actionLabel {
                        Text(actionLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tint)
                            .padding(.top, 2)
                    }
                }
                Spacer()
                if isActionable {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(!isActionable)
        .opacity(isComplete && !isActionable ? 0.7 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number) of 3: \(title)")
        .accessibilityValue(isComplete ? "Completed" : (isActionable ? "Tap to start" : "Locked"))
        .accessibilityHint(detail)
    }

    /// Connected Macs section — visible only once the user has paired at
    /// least one Mac. Lists each paired device with active state and last-seen
    /// time. The security-critical "Revoke All Pairings" sits at the bottom
    /// with a confirmation dialog. Per-device revoke is a future enhancement.
    /// The destructive action is *not* in the audit section anymore.
    private var connectedMacsSection: some View {
        Section {
            ForEach(pairedDevices, id: \.id) { device in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: device.isActive ? "laptopcomputer" : "laptopcomputer.slash")
                            .foregroundStyle(device.isActive ? .green : .secondary)
                        Text(device.name)
                            .font(.body)
                        Spacer()
                        if device.isActive {
                            Text("Active").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if let lastSeen = device.lastSeenAt {
                        Text("Last seen \(lastSeen, style: .relative) ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Awaiting first connection")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
            Button(role: .destructive) {
                HapticFeedback.notification(.warning)
                showRevokeConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.shield.fill")
                    Text("Revoke All Pairings")
                }
            }
            .confirmationDialog(
                "Revoke all pairings?",
                isPresented: $showRevokeConfirmation,
                titleVisibility: .visible
            ) {
                Button("Revoke All", role: .destructive) {
                    Task { await appState.revokeAllPairings() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Paired Macs will lose access. They will need to scan a new QR code to reconnect.")
            }
        } header: {
            Text("Connected Macs (\(pairedDevices.count))")
        } footer: {
            if let lastExport = appState.syncConfiguration.lastExportAt {
                Text("Last sync \(lastExport, style: .relative) ago.")
                    .font(.caption)
            }
        }
    }

    /// Inline warning row shown inside Getting Started when the user has granted
    /// Health access but the probe found no data — usually indicates a silent
    /// per-category denial. Surfaces a Settings deep link without claiming what
    /// we can't actually verify.
    private var limitedAccessWarningRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text("HealthSync isn't seeing any data")
                    .font(.subheadline.weight(.medium))
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            }
            Text("If you have data in Apple Health, open Settings to enable the categories you want to share.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.caption.weight(.semibold))
        }
    }


    private var serverSection: some View {
        Section {
            // Status indicator with animated symbol
            HStack {
                Image(systemName: appState.isServerRunning ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                    .foregroundStyle(appState.isServerRunning ? .green : .secondary)
                    .symbolEffect(.variableColor, isActive: appState.isServerRunning)
                Text("Status")
                Spacer()
                Text(appState.isServerRunning ? "Running" : "Stopped")
                    .foregroundStyle(.secondary)
            }

            if appState.isServerRunning {
                LabeledContent("Port", value: String(appState.serverPort))

                Button {
                    HapticFeedback.impact(.light)
                    Task { await appState.stopServer() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pause.fill")
                        Text("Stop Sharing")
                    }
                    .foregroundStyle(.red)
                }
                .liquidGlassButtonStyle(.standard)
            } else {
                Button {
                    HapticFeedback.impact(.medium)
                    Task { await appState.startServer() }
                } label: {
                    if appState.isServerStarting {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Starting...")
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Start Sharing")
                        }
                    }
                }
                .liquidGlassButtonStyle(.prominent)
                .disabled(appState.isServerStarting)
            }
        } header: {
            Text("Sharing")
        } footer: {
            if appState.isServerRunning {
                Label("Screen stays on while pairing. You can lock the phone after a Mac connects.",
                      systemImage: "sun.max.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if !hasPairedDevice {
                Text("Turn this on to make your iPhone visible to the HealthSync CLI on your Mac.")
                    .font(.caption)
            }
        }
        .animation(.smooth, value: appState.isServerRunning)
    }

    @State private var showingShareSheet = false
    @State private var qrImageToShare: UIImage?
    @State private var qrPayloadToShare: String?
    @State private var qrExpirationToShare: Date?
    @State private var showCopiedFeedback = false
    @State private var showRevokeConfirmation = false
    @State private var pendingSensitiveType: HealthDataType?
    @State private var showFingerprintExpanded = false
    @State private var showingManualExport = false

    /// Static expiry display. The previous live ticker created anxiety while the
    /// user was mid-pairing on a Mac across the room. A static "Valid until 3:42 PM"
    /// reads as confidence; the row updates only when the code actually expires
    /// (checked via TimelineView at a 30s cadence — visually quiet, no per-second
    /// repaint).
    @ViewBuilder
    private func expirationCountdown(for expiresAt: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let expired = expiresAt < context.date
            LabeledContent("Valid until") {
                if expired {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                        Text("Expired — tap Refresh")
                            .foregroundStyle(.orange)
                            .font(.callout)
                    }
                } else {
                    Text(expiresAt, format: .dateTime.hour().minute())
                        .foregroundStyle(.secondary)
                        .font(.callout)
                        .monospacedDigit()
                }
            }
        }
    }

    /// Fingerprint row that expands on tap to show the full SHA-256 in monospaced
    /// body text with a copy button — required for the user to verify it against
    /// the Mac CLI display during pairing.
    @ViewBuilder
    private func fingerprintRow(_ fingerprint: String) -> some View {
        DisclosureGroup(isExpanded: $showFingerprintExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                Text(fingerprint)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                Button {
                    UIPasteboard.general.string = fingerprint
                    HapticFeedback.notification(.success)
                } label: {
                    Label("Copy Fingerprint", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        } label: {
            LabeledContent("Fingerprint") {
                Text(fingerprint)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var pairingSection: some View {
        Section("Pairing") {
            if let qr = appState.pairingQRCode {
                // Compute payload for QR display
                let payload = qrPayloadString(for: qr)

                // QR Code display
                QRCodeView(text: payload)
                    .padding(.vertical, 8)

                // Pairing details
                LabeledContent("Code") {
                    Button {
                        UIPasteboard.general.string = qr.code
                        HapticFeedback.notification(.success)
                    } label: {
                        HStack(spacing: 4) {
                            Text(qr.code)
                                .font(.system(.body, design: .monospaced))
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.tint)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Pairing code \(qr.code), tap to copy")
                }
                expirationCountdown(for: qr.expiresAt)
                fingerprintRow(qr.certificateFingerprint)

                // Action buttons - separate rows for clear tap targets
                Button {
                    HapticFeedback.impact(.light)
                    Task { await appState.refreshPairingCode() }
                } label: {
                    if appState.isRefreshing {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Refreshing...")
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Code")
                        }
                    }
                }
                .liquidGlassButtonStyle(.standard)
                .disabled(appState.isRefreshing)

                // Copy button - reads CURRENT appState at tap time
                Button {
                    guard let currentQR = appState.pairingQRCode else { return }
                    let currentPayload = qrPayloadString(for: currentQR)
                    copyPayloadToClipboard(currentPayload, expiresAt: currentQR.expiresAt)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                        Text(showCopiedFeedback ? "Copied!" : "Copy to Clipboard")
                    }
                }
                .liquidGlassButtonStyle(showCopiedFeedback ? .prominent : .standard)
                .disabled(appState.isRefreshing)

                // Share button - reads CURRENT appState at tap time
                Button {
                    HapticFeedback.impact(.light)
                    guard let currentQR = appState.pairingQRCode else { return }
                    let currentPayload = qrPayloadString(for: currentQR)
                    if let image = QRCodeRenderer.render(payload: currentPayload) {
                        qrImageToShare = image
                        qrPayloadToShare = currentPayload
                        qrExpirationToShare = currentQR.expiresAt
                        showingShareSheet = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share QR Code")
                    }
                }
                .liquidGlassButtonStyle(.standard)
                .disabled(appState.isRefreshing)
                .sheet(isPresented: $showingShareSheet) {
                    if let image = qrImageToShare,
                       let payload = qrPayloadToShare,
                       let expiration = qrExpirationToShare {
                        ShareSheet(
                            items: [image],
                            activities: [CopyPayloadActivity(payload: payload, image: image, expiration: expiration)],
                            excludedActivityTypes: [.copyToPasteboard]
                        )
                    } else if let image = qrImageToShare {
                        ShareSheet(items: [image])
                    }
                }

                // First-pair instructions — hidden once a Mac is paired since
                // the user no longer needs them. Tucked in a DisclosureGroup
                // so even pre-pair the user can dismiss them after reading.
                if !hasPairedDevice {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Open Terminal on your Mac and install the CLI:")
                                .font(.footnote)
                            Text("brew install mneves75/tap/healthsync")
                                .font(.footnote.monospaced())
                                .textSelection(.enabled)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                            Text("2. Tap \u{201C}Copy to Clipboard\u{201D} above, then run on your Mac:")
                                .font(.footnote)
                            Text("healthsync scan")
                                .font(.footnote.monospaced())
                                .textSelection(.enabled)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                            Text("3. Keep this iPhone app open until pairing finishes.")
                                .font(.footnote)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    } label: {
                        Label("How to pair your Mac", systemImage: "info.circle")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                if hasPairedDevice {
                    ContentUnavailableView {
                        Label("Sharing Off", systemImage: "qrcode")
                    } description: {
                        Text("Tap \u{201C}Start Sharing\u{201D} above when you want your paired Mac to fetch fresh data.")
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ContentUnavailableView {
                        Label("Not Sharing Yet", systemImage: "qrcode")
                    } description: {
                        Text("Tap \u{201C}Start Sharing\u{201D} above to generate a pairing QR code for your Mac.")
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .animation(.smooth, value: appState.pairingQRCode != nil)
        .animation(.smooth, value: appState.isRefreshing)
    }

    /// Copies QR pairing payload to clipboard with BOTH text AND image.
    ///
    /// CRITICAL: This function receives the SAME payload string that QRCodeView displays,
    /// ensuring the copied QR always matches what's shown on screen.
    ///
    /// Universal Clipboard between iOS and macOS is notoriously unreliable - text sometimes
    /// fails to sync while images work, or vice versa. By setting BOTH representations:
    /// - CLI tries JSON text first (fastest, most reliable when it works)
    /// - CLI falls back to QR image scanning if text isn't available
    /// - Both are set atomically from the same payload, so they're guaranteed to match
    ///
    /// Uses setItems with expiration to ensure stale clipboard data doesn't persist.
    private func copyPayloadToClipboard(_ payload: String, expiresAt: Date) {
        guard !payload.isEmpty else {
            HapticFeedback.notification(.error)
            return
        }

        // Generate QR image from the SAME payload string that QRCodeView displays
        guard let qrImage = QRCodeRenderer.render(payload: payload),
              let pngData = qrImage.pngData() else {
            // Fallback to text-only if image generation fails
            PairingClipboard.setTextPayload(payload, expiration: expiresAt)
            HapticFeedback.notification(.success)
            showCopiedFeedback = true
            resetCopiedFeedback()
            return
        }

        // Set BOTH text AND image atomically with 5-minute expiration.
        PairingClipboard.setPayload(payload, pngData: pngData, expiration: expiresAt)

        HapticFeedback.notification(.success)
        showCopiedFeedback = true
        resetCopiedFeedback()
    }

    /// Resets the "Copied!" feedback after a delay
    private func resetCopiedFeedback() {
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                showCopiedFeedback = false
            }
        }
    }

    /// Manual Export — opens a sheet that fetches the enabled types over a
    /// chosen date range and presents a system share sheet so the user can
    /// save to Files / iCloud Drive / AirDrop / Mail / Messages without ever
    /// pairing a Mac. The iPhone-side counterpart to the Mac CLI's fetch.
    private var manualExportSection: some View {
        Section {
            Button {
                HapticFeedback.impact(.light)
                showingManualExport = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.on.square")
                        .foregroundStyle(.tint)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export to a File")
                            .foregroundStyle(.primary)
                        Text("Save your data as CSV or JSON without a Mac")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the manual export screen")
        } header: {
            Text("Export")
        }
    }

    private var dataTypesSection: some View {
        Section {
            ForEach(HealthDataType.Category.allCases, id: \.self) { category in
                if !typesIn(category).isEmpty {
                    categoryRow(for: category)
                }
            }
        } header: {
            HStack {
                Text("Shared Categories")
                Spacer()
                Text("\(appState.syncConfiguration.enabledTypes.count) of \(HealthDataType.allCases.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("Sensitive categories (reproductive health, mental-health symptoms, alcohol, cardiac alerts) are off by default. Tap any to enable.")
                .font(.caption)
        }
        .alert("Enable sensitive types?", isPresented: Binding(
            get: { showSensitiveConfirmation != nil },
            set: { if !$0 { showSensitiveConfirmation = nil } }
        )) {
            Button("Cancel", role: .cancel) { showSensitiveConfirmation = nil }
            Button("Apply Preset", role: .destructive) {
                if let preset = showSensitiveConfirmation {
                    applyPreset(preset)
                }
                showSensitiveConfirmation = nil
            }
        } message: {
            Text("This preset enables types covering sensitive health data including reproductive health and cardiac events. You can disable individual types afterward.")
        }
        .alert("Enable sensitive category?", isPresented: Binding(
            get: { pendingSensitiveType != nil },
            set: { if !$0 { pendingSensitiveType = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingSensitiveType = nil }
            Button("Enable", role: .destructive) {
                if let type = pendingSensitiveType {
                    appState.toggleType(type, enabled: true)
                }
                pendingSensitiveType = nil
            }
        } message: {
            if let type = pendingSensitiveType {
                Text("Share \(type.displayName) with your Mac? You can turn this off any time.")
            }
        }
    }

    /// Toolbar version of the preset menu — replaces the in-list row that was
    /// disguised as content. The wand icon is the standard iOS metaphor for
    /// "smart shortcuts." Disable All is *not* in this menu — it's intentionally
    /// hard to reach to avoid one-tap nukes; users can still toggle off
    /// individually or use the iOS Settings.app revoke path.
    private var presetMenuToolbar: some View {
        Menu {
            Section("Apply Preset") {
                ForEach(HealthDataType.Preset.allCases, id: \.self) { preset in
                    Button {
                        HapticFeedback.impact(.light)
                        let hasSensitive = preset.types.contains(where: { $0.isSensitive })
                        if hasSensitive {
                            showSensitiveConfirmation = preset
                        } else {
                            applyPreset(preset)
                        }
                    } label: {
                        Label(preset.displayName, systemImage: preset.iconSystemName)
                    }
                }
            }
        } label: {
            Image(systemName: "wand.and.stars")
                .accessibilityLabel("Quick Presets")
        }
    }

    private func categoryRow(for category: HealthDataType.Category) -> some View {
        let types = typesIn(category)
        let enabledCount = types.filter { appState.syncConfiguration.enabledTypes.contains($0) }.count
        let isExpanded = Binding(
            get: { expandedCategories.contains(category) || !typeSearch.isEmpty },
            set: { newValue in
                if newValue { expandedCategories.insert(category) }
                else { expandedCategories.remove(category) }
            }
        )

        return DisclosureGroup(isExpanded: isExpanded) {
            ForEach(types) { type in
                typeToggleRow(type)
            }
        } label: {
            HStack {
                Image(systemName: category.iconSystemName)
                    .foregroundStyle(.tint)
                    .frame(width: 24)
                Text(category.displayName)
                Spacer()
                Text("\(enabledCount)/\(types.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func typeToggleRow(_ type: HealthDataType) -> some View {
        let isOn = appState.syncConfiguration.enabledTypes.contains(type)
        return Toggle(isOn: Binding(
            get: { isOn },
            set: { newValue in
                // Sensitive types require explicit confirmation when turning ON.
                // Turning off is always immediate.
                if newValue && type.isSensitive && !isOn {
                    pendingSensitiveType = type
                } else {
                    appState.toggleType(type, enabled: newValue)
                }
            }
        )) {
            HStack(spacing: 8) {
                Text(type.displayName)
                if type.isSensitive {
                    Text("Sensitive")
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.orange.opacity(0.18)))
                        .foregroundStyle(.orange)
                }
            }
        }
        .accessibilityHint(type.isSensitive ? "Sensitive health data category" : "")
    }

    private func typesIn(_ category: HealthDataType.Category) -> [HealthDataType] {
        let all = HealthDataType.allCases.filter { $0.category == category }
        guard !typeSearch.isEmpty else { return all }
        let q = typeSearch.lowercased()
        return all.filter { $0.displayName.lowercased().contains(q) || $0.rawValue.lowercased().contains(q) }
    }

    private func applyPreset(_ preset: HealthDataType.Preset) {
        appState.setEnabledTypes(Array(preset.types))
    }

    private var auditSection: some View {
        // Audit log is now read-only. Revoke moved to the Connected Macs section
        // where it belongs IA-wise (security action against the connected list).
        Section("Audit") {
            if auditEvents.isEmpty {
                ContentUnavailableView {
                    Label("No Events", systemImage: "list.bullet.clipboard")
                } description: {
                    Text("No audit events yet.")
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(auditEvents.prefix(10), id: \.id) { event in
                    NavigationLink {
                        AuditEventDetailView(event: event)
                    } label: {
                        HStack {
                            Image(systemName: auditEventIcon(for: event.eventType))
                                .foregroundStyle(auditEventColor(for: event.eventType))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(auditEventLabel(for: event.eventType))
                                    .font(.subheadline)
                                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if auditEvents.count > 10 {
                    NavigationLink {
                        AuditLogView()
                    } label: {
                        Label("View All \(auditEvents.count) Events", systemImage: "list.bullet.rectangle")
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    /// Returns appropriate SF Symbol for audit event type. Matches by exact event name
    /// and falls back to category prefix (the part before the dot). The previous
    /// implementation used `.contains("auth")` which also matched `auth.healthkit_revoke`,
    /// causing the auth and revoke branches to collide.
    private func auditEventIcon(for eventType: String) -> String {
        // Specific matches first
        switch eventType {
        case "auth.revoke":                  return "xmark.shield.fill"
        case "auth.healthkit":                return "heart.text.square.fill"
        case "auth.pair":                     return "person.badge.key.fill"
        case "api.server_start":              return "play.circle.fill"
        case "api.server_stop":               return "stop.circle.fill"
        case "api.request":                   return "arrow.down.circle"
        case "api.request_invalid":           return "exclamationmark.circle.fill"
        case "security.unauthorized_access":  return "lock.trianglebadge.exclamationmark.fill"
        case "security.rate_limit_exceeded":  return "speedometer"
        case "data.read":                     return "doc.text.fill"
        case "data.routes_read":              return "map.fill"
        case "data.manual_export":            return "square.and.arrow.up.on.square.fill"
        default: break
        }
        // Category prefix fallback
        switch eventType.split(separator: ".").first.map(String.init) ?? "" {
        case "auth":     return "person.badge.key.fill"
        case "api":      return "server.rack"
        case "security": return "lock.shield.fill"
        case "data":     return "doc.text.fill"
        default:         return "info.circle"
        }
    }

    /// Returns appropriate color for audit event type. Severity precedence:
    /// security alerts (red) > revoke (red) > data access (orange) > auth (blue).
    /// Generic api.* events use neutral secondary; only server-state changes
    /// get colored to draw the eye to lifecycle events.
    private func auditEventColor(for eventType: String) -> Color {
        if eventType.hasPrefix("security.") { return .red }
        if eventType == "auth.revoke" || eventType == "api.request_invalid" { return .red }
        if eventType == "api.server_start" || eventType == "api.server_stop" { return .green }
        switch eventType.split(separator: ".").first.map(String.init) ?? "" {
        case "data":     return .orange
        case "auth":     return .blue
        default:         return .secondary
        }
    }

    /// Human-readable label for an audit event type.
    private func auditEventLabel(for eventType: String) -> String {
        switch eventType {
        case "auth.healthkit":                return "HealthKit Authorization"
        case "auth.pair":                     return "Device Paired"
        case "auth.revoke":                   return "Pairings Revoked"
        case "api.server_start":              return "Server Started"
        case "api.server_stop":               return "Server Stopped"
        case "api.request":                   return "API Request"
        case "api.request_invalid":           return "Invalid Request"
        case "security.unauthorized_access":  return "Unauthorized Access Attempt"
        case "security.rate_limit_exceeded":  return "Rate Limit Exceeded"
        case "data.read":                     return "Health Data Read"
        case "data.routes_read":              return "GPS Routes Read"
        case "data.manual_export":            return "Manual Export"
        default:                              return eventType
        }
    }

    private var settingsSection: some View {
        Section("Settings") {
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }

            NavigationLink {
                AboutView()
            } label: {
                Label("About", systemImage: "info.circle.fill")
            }
        }
    }

    private func qrPayloadString(for qr: PairingQRCode) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return (try? String(data: encoder.encode(qr), encoding: .utf8)) ?? ""
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var activities: [UIActivity]? = nil
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: activities)
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Custom "Copy" activity that writes the payload with an expiration.
final class CopyPayloadActivity: UIActivity {
    private let payload: String
    private let image: UIImage?
    private let expiration: Date

    init(payload: String, image: UIImage?, expiration: Date) {
        self.payload = payload
        self.image = image
        self.expiration = expiration
        super.init()
    }

    override var activityType: UIActivity.ActivityType? {
        UIActivity.ActivityType("org.mvneves.healthsync.copy")
    }

    override var activityTitle: String? {
        "Copy"
    }

    override var activityImage: UIImage? {
        UIImage(systemName: "doc.on.doc")
    }

    override class var activityCategory: UIActivity.Category {
        .action
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        !payload.isEmpty
    }

    override func perform() {
        if let image, let pngData = image.pngData() {
            PairingClipboard.setPayload(payload, pngData: pngData, expiration: expiration)
        } else {
            PairingClipboard.setTextPayload(payload, expiration: expiration)
        }
        activityDidFinish(true)
    }
}

// MARK: - Haptic Feedback

/// Type-safe haptic feedback helper for iOS interactions.
/// Uses MainActor for Swift 6 concurrency safety with UIKit.
@MainActor
enum HapticFeedback {
    /// Impact feedback styles
    enum ImpactStyle {
        case light, medium, heavy, soft, rigid

        var uiStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light: return .light
            case .medium: return .medium
            case .heavy: return .heavy
            case .soft: return .soft
            case .rigid: return .rigid
            }
        }
    }

    /// Notification feedback types
    enum NotificationType {
        case success, warning, error

        var uiType: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .success: return .success
            case .warning: return .warning
            case .error: return .error
            }
        }
    }

    // Cached generators with prepare() called eagerly so the first tap doesn't
    // see the typical 50-100ms warmup delay. iOS expects prepare() before each
    // expected feedback for best latency.
    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private static let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let notifier = UINotificationFeedbackGenerator()
    private static let selector = UISelectionFeedbackGenerator()

    /// Triggers impact haptic feedback. Cached generator + prepare() eliminates
    /// first-tap latency.
    static func impact(_ style: ImpactStyle) {
        let g: UIImpactFeedbackGenerator
        switch style {
        case .light:  g = impactLight
        case .medium: g = impactMedium
        case .heavy:  g = impactHeavy
        case .soft:   g = impactSoft
        case .rigid:  g = impactRigid
        }
        g.prepare()
        g.impactOccurred()
    }

    /// Triggers notification haptic feedback (success / warning / error).
    static func notification(_ type: NotificationType) {
        notifier.prepare()
        notifier.notificationOccurred(type.uiType)
    }

    /// Triggers selection haptic feedback (subtle tick).
    static func selection() {
        selector.prepare()
        selector.selectionChanged()
    }
}

#Preview {
    let schema = Schema([
        SyncConfiguration.self,
        PairedDevice.self,
        AuditEventRecord.self
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: configuration)
    let state = AppState(modelContainer: container)
    return ContentView()
        .environment(state)
        .modelContainer(container)
}
