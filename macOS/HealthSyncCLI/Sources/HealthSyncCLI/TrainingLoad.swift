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

    /// Compute ATL/CTL/TSB from daily TSS values.
    /// Rows are sorted and date gaps are filled with TSS=0 so the EWA decay
    /// is correct even when rest days are missing from the input.
    static func compute(from dailyTSS: [DailyTSS]) -> [TrainingLoadEntry] {
        let filled = fillGaps(dailyTSS.sorted { $0.date < $1.date })

        var atl: Double = 0
        var ctl: Double = 0
        var entries: [TrainingLoadEntry] = []
        entries.reserveCapacity(filled.count)

        // Use the exact exponential decay constants from the TrainingPeaks model:
        //   new_atl = prev_atl * exp(-1/7) + tss * (1 - exp(-1/7))
        // The linear approximation (1 - 1/n) overestimates ATL by ~4.4% at steady state.
        let atlDecay  = Foundation.exp(-1.0 / atlDays)
        let ctlDecay  = Foundation.exp(-1.0 / ctlDays)
        let atlFactor = 1.0 - atlDecay
        let ctlFactor = 1.0 - ctlDecay

        for day in filled {
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

    /// Insert TSS=0 entries for any calendar day missing between first and last input date.
    private static func fillGaps(_ sorted: [DailyTSS]) -> [DailyTSS] {
        guard sorted.count >= 2 else { return sorted }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone   = TimeZone(identifier: "UTC")
        guard let first = fmt.date(from: sorted.first!.date),
              let last  = fmt.date(from: sorted.last!.date) else { return sorted }

        var byDate: [String: Double] = [:]
        for d in sorted { byDate[d.date] = d.tss }

        var result: [DailyTSS] = []
        var current = first
        let cal = Calendar(identifier: .gregorian)
        while current <= last {
            let key = fmt.string(from: current)
            result.append(DailyTSS(date: key, tss: byDate[key] ?? 0))
            current = cal.date(byAdding: .day, value: 1, to: current)!
        }
        return result
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
