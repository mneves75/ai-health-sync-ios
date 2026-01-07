// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HealthSyncCLI",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "healthsync", targets: ["HealthSyncCLI"])
    ],
    targets: [
        .executableTarget(
            name: "HealthSyncCLI"
        ),
        .testTarget(
            name: "HealthSyncCLITests",
            dependencies: ["HealthSyncCLI"]
        )
    ]
)
