// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Models

struct AnomalyResult: Encodable {
    let date: String
    let type: String
    let value: Double
    let mean: Double
    let stdDev: Double
    let zScore: Double
    let isAnomaly: Bool
}

// MARK: - Statistics helpers

private func mean(_ values: [Double]) -> Double {
    guard !values.isEmpty else { return 0 }
    return values.reduce(0, +) / Double(values.count)
}

private func stdDev(_ values: [Double], avg: Double) -> Double {
    guard values.count > 1 else { return 0 }
    let variance = values.reduce(0.0) { $0 + ($1 - avg) * ($1 - avg) } / Double(values.count - 1)
    return variance.squareRoot()
}

// MARK: - Detector

struct AnomalyDetector {
    /// Z-score threshold above which a sample is flagged as anomalous.
    let threshold: Double

    init(threshold: Double = 2.5) {
        self.threshold = threshold
    }

    /// Detect outliers in a per-type series using z-score on the full window.
    /// Returns one result per input sample with computed statistics.
    func detect(samples: [(date: String, type: String, value: Double)]) -> [AnomalyResult] {
        // Group by type, compute per-type statistics
        var byType: [String: [Double]] = [:]
        for s in samples {
            byType[s.type, default: []].append(s.value)
        }

        var stats: [String: (mean: Double, stdDev: Double)] = [:]
        for (type, values) in byType {
            let avg = mean(values)
            stats[type] = (avg, stdDev(values, avg: avg))
        }

        return samples.map { s in
            let (avg, sd) = stats[s.type] ?? (s.value, 0)
            let z = sd > 0 ? abs(s.value - avg) / sd : 0
            return AnomalyResult(
                date: s.date,
                type: s.type,
                value: s.value,
                mean: avg,
                stdDev: sd,
                zScore: z,
                isAnomaly: z >= threshold
            )
        }
    }
}

// MARK: - CSV input parser

enum AnomalyInputError: Error, CustomStringConvertible {
    case emptyFile
    case missingColumn(String)
    case invalidRow(Int, String)

    var description: String {
        switch self {
        case .emptyFile:                return "Input file is empty."
        case .missingColumn(let col):   return "CSV must have a '\(col)' column."
        case .invalidRow(let n, let v): return "Row \(n): cannot parse value '\(v)'."
        }
    }
}

/// Parse a CSV produced by `healthsync fetch --format csv`.
/// The fetch command uses semicolons: id;type;value;unit;startDate;endDate;sourceName
func parseAnomalyCSV(_ text: String) throws -> [(date: String, type: String, value: Double)] {
    let lines = text
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty && !$0.hasPrefix("#") }

    guard !lines.isEmpty else { throw AnomalyInputError.emptyFile }

    let header = lines[0].lowercased().components(separatedBy: ";")

    func colIndex(_ name: String) throws -> Int {
        guard let idx = header.firstIndex(of: name) else {
            throw AnomalyInputError.missingColumn(name)
        }
        return idx
    }

    let typeIdx  = try colIndex("type")
    let dateIdx  = try colIndex("startdate")
    let valueIdx = try colIndex("value")

    var result: [(date: String, type: String, value: Double)] = []
    for (i, line) in lines.dropFirst().enumerated() {
        let cols = line.components(separatedBy: ";")
        guard cols.count > max(typeIdx, dateIdx, valueIdx) else { continue }
        let typeStr  = cols[typeIdx].trimmingCharacters(in: .whitespaces)
        let dateStr  = String(cols[dateIdx].trimmingCharacters(in: .whitespaces).prefix(10))  // YYYY-MM-DD
        let valueStr = cols[valueIdx].trimmingCharacters(in: .whitespaces)
        guard let val = Double(valueStr) else {
            throw AnomalyInputError.invalidRow(i + 2, valueStr)
        }
        result.append((date: dateStr, type: typeStr, value: val))
    }
    return result
}

// MARK: - Output

func printAnomalyCSV(_ results: [AnomalyResult], onlyAnomalies: Bool) {
    print("date,type,value,mean,stdDev,zScore,isAnomaly")
    let fmt = { (v: Double) in String(format: "%.4f", v) }
    for r in results {
        if onlyAnomalies && !r.isAnomaly { continue }
        print("\(r.date),\(r.type),\(fmt(r.value)),\(fmt(r.mean)),\(fmt(r.stdDev)),\(fmt(r.zScore)),\(r.isAnomaly)")
    }
}

func printAnomalyJSON(_ results: [AnomalyResult], onlyAnomalies: Bool) throws {
    let filtered = onlyAnomalies ? results.filter { $0.isAnomaly } : results
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(filtered)
    print(String(decoding: data, as: UTF8.self))
}
