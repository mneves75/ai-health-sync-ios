// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation
import os

enum LogSubsystem {
    static let app = "org.mvneves.healthsync"
}

enum LogCategory {
    static let app = "app"
    static let health = "health"
    static let network = "network"
    static let security = "security"
    static let audit = "audit"
}

struct AppLoggers {
    static let app = Logger(subsystem: LogSubsystem.app, category: LogCategory.app)
    static let health = Logger(subsystem: LogSubsystem.app, category: LogCategory.health)
    static let network = Logger(subsystem: LogSubsystem.app, category: LogCategory.network)
    static let security = Logger(subsystem: LogSubsystem.app, category: LogCategory.security)
    static let audit = Logger(subsystem: LogSubsystem.app, category: LogCategory.audit)
}
