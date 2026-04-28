// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

/// Manual data export — fetches HealthKit samples for a chosen date range and
/// writes them to a temp file the user can share or save via the system share
/// sheet (Files app, AirDrop, Mail, Messages, iCloud Drive, etc.).
///
/// This is the iPhone-side counterpart to the Mac CLI's `healthsync fetch`.
/// A non-tech user can grab their data without ever touching a Mac.
struct ManualExportView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var range: TimeRange = .lastWeek
    @State private var format: AppState.ManualExportFormat = .csv
    @State private var customStart = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var customEnd = Date()
    @State private var isExporting = false
    @State private var exportedFile: ExportFile?
    @State private var errorMessage: String?

    enum TimeRange: String, CaseIterable, Identifiable {
        case today, lastWeek, lastMonth, lastQuarter, custom
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .today:        return "Today"
            case .lastWeek:     return "Last 7 days"
            case .lastMonth:    return "Last 30 days"
            case .lastQuarter:  return "Last 90 days"
            case .custom:       return "Custom"
            }
        }
    }

    struct ExportFile: Identifiable {
        let id = UUID()
        let url: URL
        let sampleCount: Int
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Time Range") {
                    Picker("Range", selection: $range) {
                        ForEach(TimeRange.allCases) { r in
                            Text(r.displayName).tag(r)
                        }
                    }
                    if range == .custom {
                        DatePicker("From", selection: $customStart,
                                   in: ...customEnd, displayedComponents: .date)
                        DatePicker("To", selection: $customEnd,
                                   in: customStart...Date(), displayedComponents: .date)
                    }
                }
                Section("Format") {
                    Picker("Format", selection: $format) {
                        Text("CSV").tag(AppState.ManualExportFormat.csv)
                        Text("JSON").tag(AppState.ManualExportFormat.json)
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    LabeledContent("Categories",
                                   value: "\(appState.syncConfiguration.enabledTypes.count) selected")
                } footer: {
                    Text("Adjust which categories to include from the main screen's Shared Categories section.")
                }
                Section {
                    Button {
                        Task { await runExport() }
                    } label: {
                        if isExporting {
                            HStack(spacing: 8) {
                                ProgressView().controlSize(.small)
                                Text("Exporting…")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("Export")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isExporting || appState.syncConfiguration.enabledTypes.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Manual Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $exportedFile) { file in
                ExportResultSheet(file: file) {
                    exportedFile = nil
                    dismiss()
                }
                .presentationDetents([.medium, .large])
            }
            .alert(
                "Export Failed",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var dateRange: (Date, Date) {
        let cal = Calendar.current
        let now = Date()
        switch range {
        case .today:
            return (cal.startOfDay(for: now), now)
        case .lastWeek:
            return (cal.date(byAdding: .day, value: -7, to: now) ?? now, now)
        case .lastMonth:
            return (cal.date(byAdding: .day, value: -30, to: now) ?? now, now)
        case .lastQuarter:
            return (cal.date(byAdding: .day, value: -90, to: now) ?? now, now)
        case .custom:
            let endOfDay = cal.date(bySettingHour: 23, minute: 59, second: 59, of: customEnd) ?? customEnd
            return (cal.startOfDay(for: customStart), endOfDay)
        }
    }

    private func runExport() async {
        isExporting = true
        defer { isExporting = false }
        let (start, end) = dateRange
        do {
            let result = try await appState.runManualExport(
                types: appState.syncConfiguration.enabledTypes,
                startDate: start,
                endDate: end,
                format: format
            )
            exportedFile = ExportFile(url: result.url, sampleCount: result.sampleCount)
            HapticFeedback.notification(.success)
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.notification(.error)
        }
    }
}

/// Shown on top of ManualExportView once the file is ready. Wraps a ShareLink
/// so the user can save to Files, AirDrop, email, Messages, iCloud Drive, etc.
private struct ExportResultSheet: View {
    let file: ManualExportView.ExportFile
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, options: .repeat(1))
            Text("Export Ready")
                .font(.title2.bold())
            Text("\(file.sampleCount) sample\(file.sampleCount == 1 ? "" : "s")")
                .foregroundStyle(.secondary)
            Text(file.url.lastPathComponent)
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 24)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .truncationMode(.middle)
            Spacer()
            ShareLink(item: file.url) {
                Label("Share or Save…", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            Button("Done", action: onDone)
                .padding(.bottom, 16)
        }
        .padding(.top, 48)
    }
}
