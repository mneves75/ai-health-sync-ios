// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

struct PrivacyPolicyView: View {
    private let lastUpdated = "April 27, 2026"
    private let policyVersion = "1.1"

    private let policyText = """
    HealthSync lets you share selected HealthKit data from your iPhone to your own Mac on the same local network. This policy explains what data is used, how it is used, and your choices.

    Data We Access
    - Health data you explicitly authorize. HealthSync supports the full Apple Health surface area including activity, vitals, sleep, body measurements, nutrition, symptoms, reproductive health, mental-health symptoms, hearing exposure, mobility, spirometry, and lifestyle metrics.
    - Sensitive categories (reproductive health, mental-health symptoms, alcohol use, cardiac event alerts) are off by default and require explicit per-category opt-in.
    - Device and app configuration needed for pairing and local network sharing.

    How We Use Data
    - HealthKit data is delivered only to your paired Mac over your local Wi-Fi network using mutual TLS with a self-signed certificate pinned to a fingerprint you verify during pairing.
    - We do not use HealthKit data for advertising, analytics, or tracking.
    - We do not send any data to external servers operated by us or any third party.

    Data Sharing
    - Health data is shared only with the Mac(s) you pair using a one-time code and TLS pinning.
    - You can revoke all pairings at any time from the app's main screen.

    Logs and Audit Records
    - The app stores local audit records (pairing, access requests, server start/stop, unauthorized access attempts).
    - Audit records include event type, timestamp, and minimal metadata. They do not include raw health values.

    Retention
    - Pairing records, audit logs, and your category selections are stored locally on your device.
    - There is no cloud backup of HealthSync data outside your iCloud-managed device backup.

    Security
    - Data is encrypted in transit using TLS 1.3.
    - Pairing uses short-lived codes and token-based authentication.
    - The pairing certificate's SHA-256 fingerprint is shown in the app; verify it matches the value displayed by the Mac CLI before approving the pairing.

    Your Choices
    - Grant or revoke HealthKit access in iOS Settings → Health → HealthSync.
    - Toggle individual categories from the main screen.
    - Stop the sharing server at any time. Revoke all pairings to disconnect every paired Mac.

    Contact
    - For privacy questions, contact the developer listed in the App Store listing.
    - Source code: github.com/mneves75/ai-health-sync-ios
    """

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Privacy Policy")
                        .font(.largeTitle.bold())
                    HStack(spacing: 8) {
                        Text("Version \(policyVersion)")
                        Text("•")
                        Text("Last updated \(lastUpdated)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Text(policyText)
                    .font(.body)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
