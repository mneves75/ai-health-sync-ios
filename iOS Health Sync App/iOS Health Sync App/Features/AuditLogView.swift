// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import SwiftData
import SwiftUI

/// Full audit log with date-grouping and event-type filtering. Reached from the
/// "View All N Events" link on the main screen when more than 10 events exist.
struct AuditLogView: View {
    @Query(sort: \AuditEventRecord.timestamp, order: .reverse) private var auditEvents: [AuditEventRecord]
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable {
        case all, auth, api, security, data

        var displayName: String {
            switch self {
            case .all:      return "All"
            case .auth:     return "Auth"
            case .api:      return "API"
            case .security: return "Security"
            case .data:     return "Data"
            }
        }
    }

    var body: some View {
        List {
            ForEach(grouped, id: \.0) { (dateLabel, events) in
                Section(dateLabel) {
                    ForEach(events, id: \.id) { event in
                        NavigationLink {
                            AuditEventDetailView(event: event)
                        } label: {
                            HStack {
                                Image(systemName: AuditEventStyling.icon(for: event.eventType))
                                    .foregroundStyle(AuditEventStyling.color(for: event.eventType))
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(AuditEventStyling.label(for: event.eventType))
                                        .font(.subheadline)
                                    Text(event.timestamp.formatted(date: .omitted, time: .standard))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Audit Log")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("Filter", selection: $filter) {
                    ForEach(Filter.allCases, id: \.self) { f in
                        Text(f.displayName).tag(f)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var filtered: [AuditEventRecord] {
        guard filter != .all else { return auditEvents }
        let prefix = filter.rawValue + "."
        return auditEvents.filter { $0.eventType.hasPrefix(prefix) }
    }

    private var grouped: [(String, [AuditEventRecord])] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        var buckets: [(String, [AuditEventRecord])] = []
        let dict = Dictionary(grouping: filtered) { event -> String in
            let day = cal.startOfDay(for: event.timestamp)
            if day == today { return "Today" }
            if day == yesterday { return "Yesterday" }
            return event.timestamp.formatted(date: .abbreviated, time: .omitted)
        }
        // Preserve original ordering: walk filtered events and emit unique date labels
        var seen = Set<String>()
        for event in filtered {
            let day = cal.startOfDay(for: event.timestamp)
            let key: String
            if day == today { key = "Today" }
            else if day == yesterday { key = "Yesterday" }
            else { key = event.timestamp.formatted(date: .abbreviated, time: .omitted) }
            if !seen.contains(key), let events = dict[key] {
                seen.insert(key)
                buckets.append((key, events))
            }
        }
        return buckets
    }
}

/// Detail view for a single audit event — shows the parsed details JSON.
struct AuditEventDetailView: View {
    let event: AuditEventRecord

    var body: some View {
        List {
            Section("Event") {
                LabeledContent("Type", value: AuditEventStyling.label(for: event.eventType))
                LabeledContent("Identifier", value: event.eventType)
                    .font(.system(.body, design: .monospaced))
                LabeledContent("Timestamp", value: event.timestamp.formatted(date: .complete, time: .standard))
            }
            Section("Details") {
                if let parsed = parsedDetails, !parsed.isEmpty {
                    ForEach(parsed.sorted(by: { $0.key < $1.key }), id: \.key) { kv in
                        LabeledContent(kv.key, value: kv.value)
                    }
                } else {
                    Text("No additional details.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Event Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var parsedDetails: [String: String]? {
        guard let data = event.detailJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String: String].self, from: data)
    }
}

/// Centralized styling logic for audit events — shared by ContentView and AuditLogView
/// to keep the icon/color/label mappings consistent.
enum AuditEventStyling {
    static func icon(for eventType: String) -> String {
        switch eventType {
        case "auth.revoke":                   return "xmark.shield.fill"
        case "auth.healthkit":                return "heart.text.square.fill"
        case "auth.pair":                     return "person.badge.key.fill"
        case "api.server_start":              return "play.circle.fill"
        case "api.server_stop":               return "stop.circle.fill"
        case "api.request":                   return "arrow.down.circle"
        case "api.request_invalid":           return "exclamationmark.circle.fill"
        case "security.unauthorized_access":  return "lock.trianglebadge.exclamationmark.fill"
        case "security.rate_limit_exceeded":  return "speedometer"
        case "data.read":                     return "doc.text.fill"
        case "data.routes_read":              return "map.fill"
        default: break
        }
        switch eventType.split(separator: ".").first.map(String.init) ?? "" {
        case "auth":     return "person.badge.key.fill"
        case "api":      return "server.rack"
        case "security": return "lock.shield.fill"
        case "data":     return "doc.text.fill"
        default:         return "info.circle"
        }
    }

    static func color(for eventType: String) -> Color {
        if eventType.hasPrefix("security.") { return .red }
        if eventType == "auth.revoke" || eventType == "api.request_invalid" { return .red }
        if eventType == "api.server_start" || eventType == "api.server_stop" { return .green }
        switch eventType.split(separator: ".").first.map(String.init) ?? "" {
        case "data":     return .orange
        case "auth":     return .blue
        default:         return .secondary
        }
    }

    static func label(for eventType: String) -> String {
        switch eventType {
        case "auth.healthkit":                return "HealthKit Authorization"
        case "auth.pair":                     return "Device Paired"
        case "auth.revoke":                   return "Pairings Revoked"
        case "api.server_start":              return "Server Started"
        case "api.server_stop":               return "Server Stopped"
        case "api.request":                   return "API Request"
        case "api.request_invalid":           return "Invalid Request"
        case "security.unauthorized_access":  return "Unauthorized Access Attempt"
        case "security.rate_limit_exceeded":  return "Rate Limit Exceeded"
        case "data.read":                     return "Health Data Read"
        case "data.routes_read":              return "GPS Routes Read"
        default:                              return eventType
        }
    }
}
