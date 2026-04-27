// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Models

struct DailyTSS {
    let date: String  // YYYY-MM-DD
    let tss: Double
}

struct TrainingLoadEntry: Encodable {
    let date: String
    let tss: Double
    let atl: Double   // Acute Training Load — 7-day EWA
    let ctl: Double   // Chronic Training Load — 42-day EWA
    let tsb: Double   // Training Stress Balance = CTL − ATL
}

// MARK: - Computation

struct TrainingLoadModel {
    static let atlDays: Double = 7
    static let ctlDays: Double = 42

    /// Compute ATL/CTL/TSB from an ordered array of daily TSS values (oldest first).
    static func compute(from dailyTSS: [DailyTSS]) -> [TrainingLoadEntry] {
        var atl: Double = 0
        var ctl: Double = 0
        var entries: [TrainingLoadEntry] = []
        entries.reserveCapacity(dailyTSS.count)

        let atlDecay  = 1.0 - 1.0 / atlDays
        let ctlDecay  = 1.0 - 1.0 / ctlDays
        let atlFactor = 1.0 / atlDays
        let ctlFactor = 1.0 / ctlDays

        for day in dailyTSS {
            atl = atl * atlDecay + day.tss * atlFactor
            ctl = ctl * ctlDecay + day.tss * ctlFactor
            entries.append(TrainingLoadEntry(
                date: day.date,
                tss: day.tss,
                atl: atl,
                ctl: ctl,
                tsb: ctl - atl
            ))
        }

        return entries
    }
}

// MARK: - CSV Parser

enum TrainingLoadInputError: Error, CustomStringConvertible {
    case emptyFile
    case missingDateColumn
    case missingTSSColumn
    case invalidRow(Int, String)

    var description: String {
        switch self {
        case .emptyFile:               return "Input file is empty."
        case .missingDateColumn:       return "CSV must have a 'date' column (YYYY-MM-DD)."
        case .missingTSSColumn:        return "CSV must have a 'tss' column."
        case .invalidRow(let n, let v): return "Row \(n): cannot parse TSS value '\(v)'."
        }
    }
}

/// Parse a CSV with at least `date` and `tss` columns (case-insensitive header).
/// Lines starting with '#' and blank lines are skipped.
func parseTrainingLoadCSV(_ text: String) throws -> [DailyTSS] {
    let lines = text
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty && !$0.hasPrefix("#") }

    guard !lines.isEmpty else { throw TrainingLoadInputError.emptyFile }

    let header = lines[0].lowercased().components(separatedBy: ",")
    guard let dateIdx = header.firstIndex(of: "date") else {
        throw TrainingLoadInputError.missingDateColumn
    }
    guard let tssIdx = header.firstIndex(of: "tss") else {
        throw TrainingLoadInputError.missingTSSColumn
    }

    var result: [DailyTSS] = []
    for (i, line) in lines.dropFirst().enumerated() {
        let cols = line.components(separatedBy: ",")
        guard cols.count > max(dateIdx, tssIdx) else { continue }
        let dateStr = cols[dateIdx].trimmingCharacters(in: .whitespaces)
        let tssStr  = cols[tssIdx].trimmingCharacters(in: .whitespaces)
        guard let tss = Double(tssStr) else {
            throw TrainingLoadInputError.invalidRow(i + 2, tssStr)
        }
        result.append(DailyTSS(date: dateStr, tss: tss))
    }
    return result
}

// MARK: - Output

func printTrainingLoadCSV(_ entries: [TrainingLoadEntry]) {
    print("date,tss,atl,ctl,tsb")
    let fmt = { (v: Double) in String(format: "%.2f", v) }
    for e in entries {
        print("\(e.date),\(fmt(e.tss)),\(fmt(e.atl)),\(fmt(e.ctl)),\(fmt(e.tsb))")
    }
}

func printTrainingLoadJSON(_ entries: [TrainingLoadEntry]) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(entries)
    print(String(decoding: data, as: UTF8.self))
}
