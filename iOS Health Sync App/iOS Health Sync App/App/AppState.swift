// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import CryptoKit
import Foundation
import HealthKit
import Observation
import os
import SwiftData
import SwiftUI
import UIKit

@MainActor
@Observable
final class AppState {
    private let modelContainer: ModelContainer
    private let healthService = HealthKitService()
    private let auditService: AuditService
    private let pairingService: PairingService
    private let networkServer: NetworkServer
    private let backgroundTaskManager: BackgroundTaskManaging
    private let backgroundTaskController: BackgroundTaskController
    private var notificationTask: Task<Void, Never>?

    var syncConfiguration: SyncConfiguration
    var pairingQRCode: PairingQRCode?
    var isServerRunning: Bool = false
    var isServerStarting: Bool = false
    var isRefreshing: Bool = false
    var serverPort: Int = 0
    var serverFingerprint: String = ""
    var lastError: String?
    var protectedDataAvailable: Bool = true
    var healthAuthorizationStatus: Bool = false

    init(modelContainer: ModelContainer, backgroundTaskManager: BackgroundTaskManaging = UIApplication.shared) {
        self.modelContainer = modelContainer
        self.auditService = AuditService(modelContainer: modelContainer)
        self.pairingService = PairingService(modelContainer: modelContainer)
        self.backgroundTaskManager = backgroundTaskManager
        self.backgroundTaskController = BackgroundTaskController(manager: backgroundTaskManager)
        self.networkServer = NetworkServer(
            healthService: healthService,
            pairingService: pairingService,
            auditService: auditService,
            modelContainer: modelContainer,
            protectedDataAvailable: {
                await MainActor.run { UIApplication.shared.isProtectedDataAvailable }
            },
            deviceNameProvider: {
                // Use anonymized device identifier to prevent PII exposure
                // Format: "HealthSync-XXXX" where XXXX is first 4 chars of hashed device ID
                await MainActor.run {
                    let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
                    let hash = SHA256.hash(data: Data(deviceId.utf8))
                    let shortHash = hash.prefix(4).map { String(format: "%02x", $0) }.joined()
                    return "HealthSync-\(shortHash.uppercased())"
                }
            }
        )

        // Pre-warm TLS identity on a background thread to avoid first-run UI stalls.
        Task.detached(priority: .utility) {
            _ = try? CertificateService.loadOrCreateIdentity()
        }

        let context = modelContainer.mainContext
        do {
            if let existing = try context.fetch(FetchDescriptor<SyncConfiguration>()).first {
                self.syncConfiguration = existing
            } else {
                let newConfig = SyncConfiguration()
                context.insert(newConfig)
                try context.save()
                self.syncConfiguration = newConfig
            }
        } catch {
            AppLoggers.app.error("Failed to load or create SyncConfiguration: \(error.localizedDescription, privacy: .public)")
            // Fallback to in-memory config (not persisted)
            self.syncConfiguration = SyncConfiguration()
        }

        self.protectedDataAvailable = UIApplication.shared.isProtectedDataAvailable
        self.backgroundTaskController.setOnExpiration { [weak self] in
            guard let self else { return }
            AppLoggers.app.info("Background time expired; stopping server for safety.")
            Task { await self.stopServer() }
        }
        // Notification observers are started from the App entry point on the main actor.
    }

    deinit {}

    func startNotificationObservers() {
        guard notificationTask == nil else { return }

        notificationTask = Task { [weak self] in
            guard let self else { return }

            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    for await _ in NotificationCenter.default.notifications(
                        named: UIApplication.protectedDataDidBecomeAvailableNotification
                    ) {
                        await self?.handleProtectedDataAvailable()
                    }
                }

                group.addTask { [weak self] in
                    for await _ in NotificationCenter.default.notifications(
                        named: UIApplication.protectedDataWillBecomeUnavailableNotification
                    ) {
                        await self?.handleProtectedDataUnavailable()
                    }
                }

                group.addTask { [weak self] in
                    for await _ in NotificationCenter.default.notifications(
                        named: UIApplication.didBecomeActiveNotification
                    ) {
                        await self?.handleAppDidBecomeActive()
                    }
                }
            }
        }
    }

    func requestHealthAuthorization() async {
        do {
            guard await healthService.isAvailable() else {
                healthAuthorizationStatus = false
                lastError = "Health data is unavailable on this device."
                await auditService.record(eventType: "auth.healthkit", details: ["status": "unavailable"])
                return
            }

            // Show the authorization dialog
            let dialogShown = try await healthService.requestAuthorization(for: syncConfiguration.enabledTypes)

            // NOTE: For READ-only permissions, Apple hides whether user granted or denied.
            // requestAuthorization returns true if the dialog was shown successfully,
            // NOT whether the user approved. We can only know the dialog was presented.
            // Use hasRequestedAuthorization to verify the dialog was shown.
            healthAuthorizationStatus = await healthService.hasRequestedAuthorization(for: syncConfiguration.enabledTypes)

            await auditService.record(eventType: "auth.healthkit", details: [
                "dialogShown": String(dialogShown),
                "requested": String(healthAuthorizationStatus)
            ])
        } catch {
            lastError = "HealthKit authorization failed: \(error.localizedDescription)"
        }
    }

    private var isRunningInSimulator: Bool {
#if targetEnvironment(simulator)
        true
#else
        false
#endif
    }

    func toggleType(_ type: HealthDataType, enabled: Bool) {
        var types = syncConfiguration.enabledTypes
        if enabled {
            if !types.contains(type) {
                types.append(type)
            }
        } else {
            types.removeAll { $0 == type }
        }
        syncConfiguration.enabledTypes = types
        do {
            try modelContainer.mainContext.save()
        } catch {
            AppLoggers.app.error("Failed to save type toggle: \(error.localizedDescription, privacy: .public)")
        }
    }

    func startServer() async {
        do {
            isServerStarting = true
            defer { isServerStarting = false }

            try await networkServer.start()
            isServerRunning = true
            let snapshot = await networkServer.snapshot()
            serverPort = snapshot.port
            serverFingerprint = snapshot.fingerprint
            AppLoggers.app.info("Server started - port: \(self.serverPort), fingerprint: \(self.serverFingerprint.prefix(16), privacy: .public)...")

            let host = await Task.detached(priority: .utility) {
                Self.localIPAddress() ?? "127.0.0.1"
            }.value
            AppLoggers.app.info("Resolved host IP: \(host, privacy: .public)")

            let qr = await pairingService.generateQRCode(host: host, port: serverPort, fingerprint: serverFingerprint)
            AppLoggers.app.info("Generated QR code: \(qr.code, privacy: .public), expires: \(qr.expiresAt, privacy: .public)")
            pairingQRCode = qr

            await auditService.record(eventType: "api.server_start", details: ["port": String(serverPort)])
            // Prevent auto-lock while actively sharing.
            UIApplication.shared.isIdleTimerDisabled = true
        } catch {
            isServerStarting = false
            lastError = "Failed to start server: \(error.localizedDescription)"
            AppLoggers.app.error("Server start failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func stopServer() async {
        await networkServer.stop()
        isServerRunning = false
        serverPort = 0
        pairingQRCode = nil
        await auditService.record(eventType: "api.server_stop", details: [:])
        backgroundTaskController.endIfNeeded()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func refreshPairingCode() async {
        guard isServerRunning else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let host = await Task.detached(priority: .utility) {
            Self.localIPAddress() ?? "127.0.0.1"
        }.value
        pairingQRCode = await pairingService.generateQRCode(host: host, port: serverPort, fingerprint: serverFingerprint)
    }

    func revokeAllPairings() async {
        await pairingService.revokeAll()
        await auditService.record(eventType: "auth.revoke", details: [:])
    }

    func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            backgroundTaskController.endIfNeeded()
        case .background:
            guard isServerRunning else { return }
            // Background tasks are time-limited; this is a best-effort grace period.
            // If the system denies the task, the OS may suspend networking shortly after.
            if !backgroundTaskController.beginIfNeeded() {
                AppLoggers.app.info("Background task denied; sharing may pause while app is suspended.")
            }
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    nonisolated private static func localIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var pointer = firstAddr
        while true {
            let interface = pointer.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                        let bytes = hostname.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
                        address = String(decoding: bytes, as: UTF8.self)
                        break
                    }
                }
            }
            if let next = interface.ifa_next {
                pointer = next
            } else {
                break
            }
        }
        return address
    }

    private func handleProtectedDataAvailable() {
        protectedDataAvailable = true
    }

    private func handleProtectedDataUnavailable() {
        protectedDataAvailable = false
    }

    private func handleAppDidBecomeActive() {
        // Refresh protected data status when app becomes active
        // The initial check in init() may run before UIApplication is ready
        protectedDataAvailable = UIApplication.shared.isProtectedDataAvailable

        // Also refresh HealthKit authorization status
        Task { await refreshHealthAuthorizationStatus() }
    }

    private func refreshHealthAuthorizationStatus() async {
        guard await healthService.isAvailable() else {
            healthAuthorizationStatus = false
            return
        }

        // NOTE: For READ-only permissions, Apple hides whether user granted or denied.
        // We can only check if we've REQUESTED authorization (user saw the dialog).
        // This is Apple's privacy design - apps can't know if health data access was denied.
        healthAuthorizationStatus = await healthService.hasRequestedAuthorization(for: syncConfiguration.enabledTypes)
    }
}
