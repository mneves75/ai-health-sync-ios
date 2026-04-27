// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation
import UIKit

/// User-facing error model. Wraps the raw underlying error and provides a clean
/// title, message, and optional recovery action so the UI can surface concrete
/// next steps instead of raw `error.localizedDescription` strings (which leak
/// Network.framework / Security.framework jargon).
struct AppError: Sendable, Equatable {
    let kind: Kind
    let title: String
    let message: String
    let recovery: Recovery?

    enum Kind: String, Sendable {
        case networkUnavailable
        case serverPortBusy
        case certificateFailure
        case healthKitUnavailable
        case healthKitDenied
        case healthKitAuthFailed
        case pairingFailed
        case generic
    }

    /// Optional recovery action shown as a button on the error alert.
    struct Recovery: Sendable, Equatable {
        let label: String
        let kind: Kind

        enum Kind: String, Sendable {
            case openSettings
            case retry
            case openWiFiSettings
        }
    }

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.kind == rhs.kind && lhs.title == rhs.title && lhs.message == rhs.message
    }

    // MARK: - Constructors

    static func networkUnavailable() -> AppError {
        AppError(
            kind: .networkUnavailable,
            title: "Wi-Fi Required",
            message: "HealthSync needs a Wi-Fi connection to share data with your Mac. Connect to the same network as your Mac and try again.",
            recovery: Recovery(label: "Open Wi-Fi Settings", kind: .openWiFiSettings)
        )
    }

    static func serverPortBusy() -> AppError {
        AppError(
            kind: .serverPortBusy,
            title: "Port In Use",
            message: "Another app on this iPhone is using the network port HealthSync needs. Stop any other sharing tools and try again.",
            recovery: Recovery(label: "Retry", kind: .retry)
        )
    }

    static func certificateFailure() -> AppError {
        AppError(
            kind: .certificateFailure,
            title: "Certificate Error",
            message: "HealthSync could not create or load the security certificate required for encrypted sharing. Try restarting the app.",
            recovery: nil
        )
    }

    static func healthKitUnavailable() -> AppError {
        AppError(
            kind: .healthKitUnavailable,
            title: "Health Data Unavailable",
            message: "Apple Health is not available on this device. HealthSync requires an iPhone with the Health app installed.",
            recovery: nil
        )
    }

    static func healthKitDenied() -> AppError {
        AppError(
            kind: .healthKitDenied,
            title: "Health Access Required",
            message: "HealthSync cannot read any health data because access has not been granted. Open Settings → Privacy & Security → Health → HealthSync to enable the categories you want to share.",
            recovery: Recovery(label: "Open Settings", kind: .openSettings)
        )
    }

    static func healthKitAuthFailed(_ underlying: Error) -> AppError {
        AppError(
            kind: .healthKitAuthFailed,
            title: "Authorization Failed",
            message: "HealthSync could not request access to your health data. \(underlying.localizedDescription)",
            recovery: Recovery(label: "Retry", kind: .retry)
        )
    }

    static func pairingFailed(_ underlying: Error) -> AppError {
        AppError(
            kind: .pairingFailed,
            title: "Pairing Failed",
            message: "Could not generate a pairing code. \(underlying.localizedDescription)",
            recovery: Recovery(label: "Retry", kind: .retry)
        )
    }

    static func generic(_ underlying: Error) -> AppError {
        AppError(
            kind: .generic,
            title: "Something Went Wrong",
            message: underlying.localizedDescription,
            recovery: Recovery(label: "Retry", kind: .retry)
        )
    }

    // MARK: - Mapping

    /// Maps a raw error from server start into a structured AppError. Inspects
    /// the error's domain and code to recognize port-in-use, certificate, and
    /// network-down conditions where possible.
    static func fromServerStart(_ error: Error) -> AppError {
        let nsError = error as NSError
        // POSIXError EADDRINUSE
        if nsError.domain == NSPOSIXErrorDomain, nsError.code == 48 { return .serverPortBusy() }
        // Network framework errors typically use NWError; check for specific keywords
        let desc = error.localizedDescription.lowercased()
        if desc.contains("address already in use") || desc.contains("eaddrinuse") {
            return .serverPortBusy()
        }
        if desc.contains("network is unavailable") || desc.contains("not connected") {
            return .networkUnavailable()
        }
        if desc.contains("certificate") || desc.contains("identity") || desc.contains("keychain") {
            return .certificateFailure()
        }
        return .generic(error)
    }
}

// MARK: - Recovery actions

/// Wrapper that gives AppError an Identifiable identity for `.alert(item:)`.
struct IdentifiableAppError: Identifiable {
    let id = UUID()
    let appError: AppError
    init(_ appError: AppError) { self.appError = appError }
}

@MainActor
enum AppErrorRecoveryRunner {
    static func run(_ recovery: AppError.Recovery) {
        switch recovery.kind {
        case .openSettings:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .openWiFiSettings:
            // App-Prefs:WIFI deep link is private API and rejected by App Review;
            // fall back to the standard app settings URL which still gets the user
            // to a settings context one tap away from Wi-Fi.
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .retry:
            break // Caller handles the retry; this branch exists for completeness.
        }
    }
}
