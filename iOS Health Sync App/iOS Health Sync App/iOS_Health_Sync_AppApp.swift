// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import os
import SwiftData
import SwiftUI

@main
struct iOS_Health_Sync_AppApp: App {
    private let modelContainer: ModelContainer
    @State private var appState: AppState

    init() {
        do {
            let schema = Schema(versionedSchema: SchemaV1.self)
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(
                for: schema,
                migrationPlan: HealthSyncMigrationPlan.self,
                configurations: configuration
            )
            self.modelContainer = container
            self._appState = State(initialValue: AppState(modelContainer: container))
        } catch {
            // Log the error for debugging
            AppLoggers.app.fault("Failed to create ModelContainer: \(error.localizedDescription, privacy: .public)")
            // Fatal error in production - cannot operate without database
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .modelContainer(modelContainer)
                .task {
                    appState.startNotificationObservers()
                }
        }
    }
}
