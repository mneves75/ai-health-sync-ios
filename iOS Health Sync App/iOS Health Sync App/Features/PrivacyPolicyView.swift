// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

struct PrivacyPolicyView: View {
    private let policyText = """
    Privacy Policy

    HealthSync lets you share selected HealthKit data from your iPhone to your own Mac on the same local network. This policy explains what data is used, how it is used, and your choices.

    Data We Access
    - Health data you explicitly authorize (for example steps, heart rate, sleep, workouts).
    - Device and app configuration needed for pairing and local network sharing.

    How We Use Data
    - We use HealthKit data only to deliver it to your paired Mac over your local network.
    - We do not use HealthKit data for advertising or tracking.

    Data Sharing
    - Health data is shared only with the Mac you pair using a one-time code and TLS pinning.
    - We do not send health data to any external servers.

    Logs and Audit Records
    - The app stores local audit records (for example pairing, access requests, and status checks).
    - Audit records include minimal metadata and hashed identifiers; they do not include raw health values.

    Retention
    - Pairing records and audit logs are stored locally on your device.
    - You can revoke all pairings from the app at any time.

    Security
    - Data is encrypted in transit using TLS.
    - Pairing uses short-lived codes and token-based authentication.

    Your Choices
    - You can grant or revoke HealthKit access in iOS Settings.
    - You can stop sharing at any time from the app.

    Contact
    - For privacy questions, contact the developer listed in the App Store listing.
    """

    var body: some View {
        ScrollView {
            Text(policyText)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
