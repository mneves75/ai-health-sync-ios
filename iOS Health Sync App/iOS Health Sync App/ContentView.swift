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

    var body: some View {
        NavigationStack {
            List {
                statusSection
                permissionsSection
                serverSection
                pairingSection
                dataTypesSection
                auditSection
                settingsSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("HealthSync")
            .onChange(of: scenePhase) { _, newPhase in
                appState.handleScenePhaseChange(newPhase)
            }
            .alert("Error", isPresented: Binding(get: { appState.lastError != nil }, set: { if !$0 { appState.lastError = nil } })) {
                Button("OK") { appState.lastError = nil }
            } message: {
                Text(appState.lastError ?? "")
            }
        }
    }

    /// App version from bundle (matches AboutView)
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var statusSection: some View {
        Section("Status") {
            LabeledContent("Version", value: appVersion)
            LabeledContent("Protected Data", value: appState.protectedDataAvailable ? "Available" : "Locked")
            // NOTE: For READ-only HealthKit permissions, Apple hides whether user granted or denied.
            // We can only know if we've requested (user saw the dialog), not if they approved.
            LabeledContent("HealthKit", value: appState.healthAuthorizationStatus ? "Requested" : "Not Requested")
            if let lastExport = appState.syncConfiguration.lastExportAt {
                LabeledContent("Last Sync", value: lastExport.formatted())
            }
        }
    }

    private var permissionsSection: some View {
        Section("Permissions") {
            Button {
                HapticFeedback.impact(.medium)
                Task { await appState.requestHealthAuthorization() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                    Text("Request HealthKit Access")
                }
            }
            .liquidGlassButtonStyle(.prominent)
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
                        Image(systemName: "stop.fill")
                        Text("Stop Sharing")
                    }
                }
                .liquidGlassButtonStyle(.standard)
                .tint(.red)
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
            Text("Sharing Server")
        } footer: {
            if appState.isServerRunning {
                Label("Screen stays on while sharing to keep the connection alive. This will use more battery than usual.",
                      systemImage: "sun.max.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

    /// Live countdown for pairing-code expiry. Refreshes every second so users see
    /// urgency. Goes orange < 60s, red when expired.
    @ViewBuilder
    private func expirationCountdown(for expiresAt: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = expiresAt.timeIntervalSince(context.date)
            let expired = remaining <= 0
            let urgent = remaining < 60 && !expired
            LabeledContent("Expires") {
                if expired {
                    Text("Expired — tap Refresh Code")
                        .foregroundStyle(.red)
                        .font(.callout)
                } else {
                    Text(expiresAt, style: .relative)
                        .foregroundStyle(urgent ? .orange : .secondary)
                        .font(urgent ? .callout.weight(.semibold) : .callout)
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
                LabeledContent("Code", value: qr.code)
                    .font(.system(.body, design: .monospaced))
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

                // Info about keeping app in foreground
                Label("Keep the app open for best reliability", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // Empty state with glass styling
                ContentUnavailableView {
                    Label("No QR Code", systemImage: "qrcode")
                } description: {
                    Text("Start sharing to generate a pairing QR code.")
                }
                .listRowBackground(Color.clear)
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

    private var dataTypesSection: some View {
        Section {
            presetMenu
            searchField
            ForEach(HealthDataType.Category.allCases, id: \.self) { category in
                if !typesIn(category).isEmpty {
                    categoryRow(for: category)
                }
            }
        } header: {
            HStack {
                Text("Shared Data Types")
                Spacer()
                Text("\(appState.syncConfiguration.enabledTypes.count) of \(HealthDataType.allCases.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("Sensitive types (reproductive health, mental-health symptoms, alcohol, cardiac event alerts) are off by default. Enable them deliberately.")
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
                Text("Enabling \(type.displayName) lets HealthSync read this category from Apple Health and transmit it to your paired Mac. You can disable it again at any time.")
            }
        }
    }

    private var presetMenu: some View {
        Menu {
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
            Divider()
            Button(role: .destructive) {
                HapticFeedback.impact(.light)
                appState.setEnabledTypes([])
            } label: {
                Label("Disable All", systemImage: "minus.circle")
            }
        } label: {
            HStack {
                Image(systemName: "wand.and.stars")
                Text("Quick Presets")
                Spacer()
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search types", text: $typeSearch)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !typeSearch.isEmpty {
                Button {
                    typeSearch = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
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
        Section("Audit") {
            Button(role: .destructive) {
                HapticFeedback.notification(.warning)
                showRevokeConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.shield.fill")
                    Text("Revoke All Pairings")
                }
            }
            .liquidGlassButtonStyle(.standard)
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
                Text("Paired Macs will lose access. They will need to scan a new QR code to reconnect. This cannot be undone.")
            }

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
    /// security alerts (red) > revoke (red) > data access (orange) > auth (blue) > api (green).
    private func auditEventColor(for eventType: String) -> Color {
        if eventType.hasPrefix("security.") { return .red }
        if eventType == "auth.revoke" || eventType == "api.request_invalid" { return .red }
        switch eventType.split(separator: ".").first.map(String.init) ?? "" {
        case "data":     return .orange
        case "auth":     return .blue
        case "api":      return .green
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
