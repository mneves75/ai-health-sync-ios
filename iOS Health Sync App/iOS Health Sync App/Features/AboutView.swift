// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var copyrightYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        List {
            // App Info Section
            Section {
                VStack(spacing: 16) {
                    // App Icon
                    Image("AboutIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    // App Name
                    Text("AI Health Sync")
                        .font(.title2)
                        .fontWeight(.semibold)

                    // Version
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // Description Section
            Section {
                Text("Securely sync your Apple HealthKit data from iPhone to Mac over your local network. Your health data never leaves your devices.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Features Section
            Section("Features") {
                FeatureRow(icon: "lock.shield.fill", color: .green, title: "Secure by Design", description: "TLS 1.3 encryption with certificate pinning")
                FeatureRow(icon: "wifi", color: .blue, title: "Local Network Only", description: "No cloud services, data stays on your devices")
                FeatureRow(icon: "qrcode", color: .purple, title: "Easy Pairing", description: "Scan a QR code to securely connect")
                FeatureRow(icon: "heart.fill", color: .pink, title: "HealthKit Integration", description: "Steps, heart rate, sleep, workouts, and more")
            }

            // Developer Section
            Section("Developer") {
                LabeledContent("Created by", value: "Marcus Neves")
                LabeledContent("Copyright", value: "\u{00A9} \(copyrightYear) Marcus Neves")
            }

            // License Section
            Section("License") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apache License 2.0")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Licensed under the Apache License, Version 2.0. You may obtain a copy of the License at apache.org/licenses/LICENSE-2.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Acknowledgments Section
            Section("Acknowledgments") {
                VStack(alignment: .leading, spacing: 12) {
                    AcknowledgmentRow(title: "Apple HealthKit", description: "Health data framework")
                    AcknowledgmentRow(title: "Apple Network Framework", description: "TLS server and Bonjour discovery")
                    AcknowledgmentRow(title: "Apple Vision Framework", description: "QR code detection")
                    AcknowledgmentRow(title: "SwiftUI & SwiftData", description: "Modern Apple UI and persistence")
                }
            }

            // Thank You Section
            Section {
                VStack(spacing: 8) {
                    Text("Thank You")
                        .font(.headline)
                    Text("Thank you for using AI Health Sync! Your privacy and data security are our top priorities.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Views

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct AcknowledgmentRow: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
