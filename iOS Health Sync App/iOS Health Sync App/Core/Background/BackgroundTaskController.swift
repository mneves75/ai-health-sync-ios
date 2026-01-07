// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import UIKit

@MainActor
protocol BackgroundTaskManaging: AnyObject {
    var isIdleTimerDisabled: Bool { get set }
    func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (@MainActor @Sendable () -> Void)?) -> UIBackgroundTaskIdentifier
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

extension UIApplication: BackgroundTaskManaging {}

@MainActor
final class BackgroundTaskController {
    private let manager: BackgroundTaskManaging
    private var onExpiration: @MainActor () -> Void
    private var taskIdentifier: UIBackgroundTaskIdentifier = .invalid

    init(manager: BackgroundTaskManaging, onExpiration: @escaping @MainActor () -> Void = {}) {
        self.manager = manager
        self.onExpiration = onExpiration
    }

    func setOnExpiration(_ handler: @escaping @MainActor () -> Void) {
        onExpiration = handler
    }

    var isActive: Bool {
        taskIdentifier != .invalid
    }

    @discardableResult
    func beginIfNeeded() -> Bool {
        guard taskIdentifier == .invalid else { return true }
        let handler: @MainActor @Sendable () -> Void = { [weak self] in
            self?.handleExpiration()
        }
        let identifier = manager.beginBackgroundTask(withName: "HealthSync Sharing", expirationHandler: handler)
        guard identifier != .invalid else {
            return false
        }
        taskIdentifier = identifier
        return true
    }

    func endIfNeeded() {
        guard taskIdentifier != .invalid else { return }
        manager.endBackgroundTask(taskIdentifier)
        taskIdentifier = .invalid
    }

    private func handleExpiration() {
        guard taskIdentifier != .invalid else { return }
        // Background tasks are time-limited; clean up promptly to avoid suspension warnings.
        manager.endBackgroundTask(taskIdentifier)
        taskIdentifier = .invalid
        onExpiration()
    }
}
