// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

/// First-launch guided introduction. Three pages explain what HealthSync does,
/// the privacy stance, and lead the user through HealthKit authorization before
/// they reach the dense main settings screen.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentPage: Int = 0
    @State private var isRequestingPermission: Bool = false

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            privacyPage.tag(1)
            permissionPage.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(Color(.systemBackground))
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 96))
                .foregroundStyle(.tint)
                .symbolEffect(.bounce, value: currentPage == 0)
            Text("Welcome to HealthSync")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Securely share Apple Health data from this iPhone to your Mac over your home Wi-Fi.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    private var privacyPage: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    withAnimation { currentPage = 0 }
                } label: {
                    Label("Back", systemImage: "chevron.backward")
                        .labelStyle(.titleAndIcon)
                        .font(.body)
                }
                .padding(.leading, 16)
                Spacer()
            }
            .padding(.top, 12)
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text("How We Protect Your Data")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 16) {
                bulletRow(icon: "wifi", title: "Local network only",
                          body: "Data is sent only to your paired Mac over your home Wi-Fi.")
                bulletRow(icon: "lock.fill", title: "Encrypted in transit",
                          body: "Mutual TLS with a self-signed certificate pinned to a fingerprint you verify.")
                bulletRow(icon: "hand.raised.fill", title: "You choose what to share",
                          body: "Pick categories one by one. Sensitive categories are off by default.")
                bulletRow(icon: "trash.fill", title: "No external servers",
                          body: "Nothing is sent to the cloud. Revoking access deletes all paired devices.")
            }
            .padding(.horizontal, 24)
            Spacer()
            Button {
                withAnimation { currentPage = 2 }
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    private var permissionPage: some View {
        VStack(spacing: 24) {
            HStack {
                Button {
                    withAnimation { currentPage = 1 }
                } label: {
                    Label("Back", systemImage: "chevron.backward")
                        .labelStyle(.titleAndIcon)
                        .font(.body)
                }
                .padding(.leading, 16)
                Spacer()
            }
            .padding(.top, 12)

            Spacer()
            Image(systemName: "heart.fill")
                .font(.system(size: 80))
                .foregroundStyle(.red)
                .symbolEffect(.pulse, options: .repeating, value: isRequestingPermission)
            Text("Grant Health Access")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("Standard categories on. Sensitive categories off until you choose. Nothing leaves this iPhone until you pair a Mac.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Text("You can change selections any time.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            VStack(spacing: 12) {
                Button {
                    Task { await requestPermission() }
                } label: {
                    HStack {
                        if isRequestingPermission { ProgressView().tint(.white) }
                        Text(isRequestingPermission ? "Opening Health…" : "Grant Health Access")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isRequestingPermission)

                Button("Set up later") {
                    hasCompletedOnboarding = true
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    private func bulletRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(body).font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    private func requestPermission() async {
        isRequestingPermission = true
        defer { isRequestingPermission = false }
        await appState.requestHealthAuthorization()
        hasCompletedOnboarding = true
    }
}
