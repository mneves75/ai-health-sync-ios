// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Testing
@testable import HealthSyncCLI

// MARK: - AnomalyDetector.detect Tests

@Suite("AnomalyDetector.detect")
struct AnomalyDetectorDetectTests {

    // MARK: Happy path — z-score formula

    @Test("Returns one result per input sample")
    func resultCountMatchesInput() {
        let detector = AnomalyDetector()
        let samples: [(date: String, type: String, value: Double)] = [
            (date: "2026-01-01", type: "heartRate", value: 60),
            (date: "2026-01-02", type: "heartRate", value: 65),
            (date: "2026-01-03", type: "heartRate", value: 70)
        ]
        let results = detector.detect(samples: samples)
        #expect(results.count == 3)
    }

    @Test("z-score is computed correctly: z = abs(value - mean) / stdDev")
    func zScoreFormula() {
        let detector = AnomalyDetector()
        // Known values: [1, 2, 3] → mean=2, stdDev=1 (sample)
        let samples: [(date: String, type: String, value: Double)] = [
            (date: "2026-01-01", type: "hr", value: 1),
            (date: "2026-01-02", type: "hr", value: 2),
            (date: "2026-01-03", type: "hr", value: 3)
        ]
        let results = detector.detect(samples: samples)
        // mean = 2, sample stdDev = sqrt(((1-2)²+(2-2)²+(3-2)²)/2) = sqrt(1) = 1
        #expect(abs(results[0].mean - 2.0) < 1e-10)
        #expect(abs(results[0].stdDev - 1.0) < 1e-10)
        #expect(abs(results[0].zScore - 1.0) < 1e-10)  // |1 - 2| / 1 = 1
        #expect(abs(results[1].zScore - 0.0) < 1e-10)  // |2 - 2| / 1 = 0
        #expect(abs(results[2].zScore - 1.0) < 1e-10)  // |3 - 2| / 1 = 1
    }

    @Test("Default threshold is 2.5")
    func defaultThresholdIs2_5() {
        let detector = AnomalyDetector()
        #expect(detector.threshold == 2.5)
    }

    @Test("isAnomaly is true only when z >= threshold")
    func isAnomalyRespectsThreshold() {
        // Use 3 values where one is a clear outlier.
        // [1, 1, 100]: mean ≈ 34, stdDev large, 100 will be anomaly.
        let detector = AnomalyDetector()
        let samples: [(date: String, type: String, value: Double)] = [
            (date: "2026-01-01", type: "hr", value: 60),
            (date: "2026-01-02", type: "hr", value: 61),
            (date: "2026-01-03", type: "hr", value: 62),
            (date: "2026-01-04", type: "hr", value: 63),
            (date: "2026-01-05", type: "hr", value: 200)  // extreme outlier
        ]
        let results = detector.detect(samples: samples)
        let outlier = results.last!
        #expect(outlier.isAnomaly)
        // Normal values should not be flagged
        let normal = results.first!
        #expect(!normal.isAnomaly)
    }

    @Test("Custom threshold is respected")
    func customThresholdRespected() {
        // With a very high threshold nothing should be flagged
        let detector = AnomalyDetector(threshold: 100.0)
        let samples: [(date: String, type: String, value: Double)] = [
            (date: "2026-01-01", type: "hr", value: 60),
            (date: "2026-01-02", type: "hr", value: 61),
            (date: "2026-01-03", type: "hr", value: 500)  // extreme outlier but threshold is 100
        ]
        let results = detector.detect(samples: samples)
        #expect(results.allSatisfy { !$0.isAnomaly })
    }

    // MARK: Per-type grouping

    @Test("Types are processed independently")
    func typesProcessedIndependently() {
        // heartRate values [60,61,62] and steps values [1000,2000,3000]
        // The z-scores for each type should be computed within that type's values only.
        let detector = AnomalyDetector()
        let samples: [(date: String, type: String, value: Double)] = [
            (date: "2026-01-01", type: "heartRate", value: 60),
            (date: "2026-01-01", type: "steps",     value: 1000),
            (date: "2026-01-02", type: "heartRate", value: 61),
            (date: "2026-01-02", type: "steps",     value: 2000),
            (date: "2026-01-03", type: "heartRate", value: 62),
            (date: "2026-01-03", type: "steps",     value: 3000)
        ]
        let results = detector.detect(samples: samples)
        let hrMean = results.filter { $0.type == "heartRate" }.first!.mean
        let stepsMean = results.filter { $0.type == "steps" }.first!.mean
        // heartRate mean ≈ 61, steps mean = 2000
        #expect(abs(hrMean - 61.0) < 1e-6)
        #expect(abs(stepsMean - 2000.0) < 1e-6)
    }

    @Test("A value that would be anomalous globally is not anomalous within its type")
    func typeGroupingPreventsCrossTypeAnomaly() {
        // heartRate [60, 62, 63] — tight cluster, no anomaly
        // steps [10000] — single value, stdDev=0, z=0, not anomaly
        // Without per-type grouping, mixing steps into HR would skew stats badly.
        let detector = AnomalyDetector()
        let samples: [(date: String, type: String, value: Double)] = [
            (date: "2026-01-01", type: "heartRate", value: 60),
            (date: "2026-01-02", type: "heartRate", value: 62),
            (date: "2026-01-03", type: "heartRate", value: 63),
            (date: "2026-01-01", type: "steps",     value: 10_000)
        ]
        let results = detector.detect(samples: samples)
        // heartRate values should all be non-anomalous (tight cluster)
        let hrResults = results.filter { $0.type == "heartRate" }
        #expect(hrResults.allSatisfy { !$0.isAnomaly })
        // steps single value: stdDev=0, z=0
        let stepsResult = results.first { $0.type == "steps" }!
        #expect(stepsResult.zScore == 0.0)
        #expect(!stepsResult.isAnomaly)
    }

    // MARK: Edge: all identical values

    @Test("All identical values produce stdDev=0 and z=0, nothing flagged")
    func allIdenticalValues() {
        let detector = AnomalyDetector()
        let samples: [(date: String, type: String, value: Double)] = [
            (date: "2026-01-01", type: "hr", value: 70),
            (date: "2026-01-02", type: "hr", value: 70),
            (date: "2026-01-03", type: "hr", value: 70)
        ]
        let results = detector.detect(samples: samples)
        #expect(results.allSatisfy { $0.stdDev == 0.0 })
        #expect(results.allSatisfy { $0.zScore == 0.0 })
        #expect(results.allSatisfy { !$0.isAnomaly })
    }

    // MARK: Edge: single sample

    @Test("Single sample produces stdDev=0, z=0, not anomalous")
    func singleSample() {
        let detector = AnomalyDetector()
        let samples: [(date: String, type: String, value: Double)] = [
            (date: "2026-01-01", type: "hr", value: 75)
        ]
        let results = detector.detect(samples: samples)
        #expect(results.count == 1)
        #expect(results[0].stdDev == 0.0)
        #expect(results[0].zScore == 0.0)
        #expect(!results[0].isAnomaly)
    }

    // MARK: Edge: empty input

    @Test("Empty input produces empty output")
    func emptyInputReturnsEmpty() {
        let detector = AnomalyDetector()
        let results = detector.detect(samples: [])
        #expect(results.isEmpty)
    }

    // MARK: Result fields

    @Test("Results preserve original date, type, and value")
    func resultsPreserveInputFields() {
        let detector = AnomalyDetector()
        let samples: [(date: String, type: String, value: Double)] = [
            (date: "2026-06-15", type: "glucose", value: 5.5),
            (date: "2026-06-16", type: "glucose", value: 6.0)
        ]
        let results = detector.detect(samples: samples)
        #expect(results[0].date == "2026-06-15")
        #expect(results[0].type == "glucose")
        #expect(results[0].value == 5.5)
    }
}

// MARK: - parseAnomalyCSV Tests

@Suite("parseAnomalyCSV")
struct ParseAnomalyCSVTests {

    // MARK: Happy path

    @Test("Parses minimal valid semicolon-delimited CSV")
    func parsesMinimalCSV() throws {
        let csv = """
        type;startdate;value
        heartRate;2026-01-01;72.0
        heartRate;2026-01-02;68.0
        """
        let result = try parseAnomalyCSV(csv)
        #expect(result.count == 2)
        #expect(result[0].type == "heartRate")
        #expect(result[0].date == "2026-01-01")
        #expect(result[0].value == 72.0)
    }

    @Test("startdate column is truncated to 10 characters (YYYY-MM-DD)")
    func startdateTruncatedTo10Chars() throws {
        let csv = """
        type;startdate;value
        hr;2026-01-15T08:30:00Z;80
        """
        let result = try parseAnomalyCSV(csv)
        #expect(result[0].date == "2026-01-15")
    }

    @Test("Comment lines starting with # are skipped")
    func commentLinesSkipped() throws {
        let csv = """
        # exported data
        type;startdate;value
        # another comment
        steps;2026-01-01;5000
        """
        let result = try parseAnomalyCSV(csv)
        #expect(result.count == 1)
        #expect(result[0].type == "steps")
    }

    @Test("Blank lines are skipped")
    func blankLinesSkipped() throws {
        let csv = "type;startdate;value\n\nhr;2026-01-01;60\n\nhr;2026-01-02;65\n"
        let result = try parseAnomalyCSV(csv)
        #expect(result.count == 2)
    }

    @Test("Columns may appear in any order")
    func columnsAnyOrder() throws {
        let csv = """
        value;type;startdate
        99;glucose;2026-03-01
        """
        let result = try parseAnomalyCSV(csv)
        #expect(result[0].value == 99.0)
        #expect(result[0].type == "glucose")
        #expect(result[0].date == "2026-03-01")
    }

    @Test("Header is case-insensitive")
    func headerCaseInsensitive() throws {
        let csv = """
        TYPE;STARTDATE;VALUE
        steps;2026-01-01;8000
        """
        let result = try parseAnomalyCSV(csv)
        #expect(result.count == 1)
        #expect(result[0].type == "steps")
    }

    @Test("Rows with too few columns are silently skipped")
    func shortRowsSkipped() throws {
        let csv = """
        type;startdate;value
        hr
        hr;2026-01-02;70
        """
        let result = try parseAnomalyCSV(csv)
        #expect(result.count == 1)
        #expect(result[0].value == 70)
    }

    // MARK: Error cases

    @Test("Throws emptyFile for empty string")
    func throwsOnEmptyString() {
        #expect(throws: AnomalyInputError.self) {
            _ = try parseAnomalyCSV("")
        }
    }

    @Test("Throws emptyFile when only whitespace/comments")
    func throwsOnOnlyComments() {
        #expect(throws: AnomalyInputError.self) {
            _ = try parseAnomalyCSV("# comment only\n")
        }
    }

    @Test("Throws missingColumn when type column absent")
    func throwsMissingTypeColumn() {
        let csv = "startdate;value\n2026-01-01;50\n"
        #expect(throws: AnomalyInputError.self) {
            _ = try parseAnomalyCSV(csv)
        }
    }

    @Test("Throws missingColumn when startdate column absent")
    func throwsMissingStartdateColumn() {
        let csv = "type;value\nhr;60\n"
        #expect(throws: AnomalyInputError.self) {
            _ = try parseAnomalyCSV(csv)
        }
    }

    @Test("Throws missingColumn when value column absent")
    func throwsMissingValueColumn() {
        let csv = "type;startdate\nhr;2026-01-01\n"
        #expect(throws: AnomalyInputError.self) {
            _ = try parseAnomalyCSV(csv)
        }
    }

    @Test("Throws invalidRow for non-numeric value")
    func throwsInvalidRowForNonNumericValue() {
        let csv = """
        type;startdate;value
        hr;2026-01-01;notanumber
        """
        #expect(throws: AnomalyInputError.self) {
            _ = try parseAnomalyCSV(csv)
        }
    }
}
