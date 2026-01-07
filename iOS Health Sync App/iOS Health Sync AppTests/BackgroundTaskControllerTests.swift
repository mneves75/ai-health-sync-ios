// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Testing
import UIKit
@testable import iOS_Health_Sync_App

@MainActor
final class MockBackgroundTaskManager: BackgroundTaskManaging {
    var isIdleTimerDisabled: Bool = false
    private var nextId: UIBackgroundTaskIdentifier = 1
    var shouldReturnInvalid: Bool = false
    private(set) var beganCount: Int = 0
    private(set) var endedIds: [UIBackgroundTaskIdentifier] = []
    private(set) var expirationHandler: (@MainActor @Sendable () -> Void)?

    func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (@MainActor @Sendable () -> Void)?) -> UIBackgroundTaskIdentifier {
        beganCount += 1
        expirationHandler = handler
        if shouldReturnInvalid {
            return .invalid
        }
        let id = nextId
        nextId += 1
        return id
    }

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        endedIds.append(identifier)
    }
}

@Test
@MainActor
func backgroundTaskControllerBeginsOnce() {
    let manager = MockBackgroundTaskManager()
    let controller = BackgroundTaskController(manager: manager)

    controller.beginIfNeeded()
    controller.beginIfNeeded()

    #expect(controller.isActive)
    #expect(manager.beganCount == 1)
}

@Test
@MainActor
func backgroundTaskControllerEnds() {
    let manager = MockBackgroundTaskManager()
    let controller = BackgroundTaskController(manager: manager)

    controller.beginIfNeeded()
    controller.endIfNeeded()

    #expect(!controller.isActive)
    #expect(manager.endedIds.count == 1)
}

@Test
@MainActor
func backgroundTaskControllerExpirationCallsHandler() {
    let manager = MockBackgroundTaskManager()
    var expired = false
    let controller = BackgroundTaskController(manager: manager) {
        expired = true
    }

    controller.beginIfNeeded()
    manager.expirationHandler?()

    #expect(expired)
    #expect(!controller.isActive)
    #expect(manager.endedIds.count == 1)
}

@Test
@MainActor
func backgroundTaskControllerBeginFailsOnInvalidIdentifier() {
    let manager = MockBackgroundTaskManager()
    manager.shouldReturnInvalid = true
    let controller = BackgroundTaskController(manager: manager)

    let started = controller.beginIfNeeded()

    #expect(!started)
    #expect(!controller.isActive)
    #expect(manager.beganCount == 1)
}
