// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Testing
@testable import HealthSyncCLI

// MARK: - TrainingLoadModel.compute Tests

@Suite("TrainingLoadModel.compute")
struct TrainingLoadModelComputeTests {

    // MARK: Empty / trivial input

    @Test("Empty input returns empty output")
    func emptyInputReturnsEmpty() {
        let result = TrainingLoadModel.compute(from: [])
        #expect(result.isEmpty)
    }

    @Test("Single day initialises ATL and CTL from zero")
    func singleDay() {
        let tss = 100.0
        let entries = TrainingLoadModel.compute(from: [DailyTSS(date: "2026-01-01", tss: tss)])
        #expect(entries.count == 1)
        let e = entries[0]
        // ATL after 1 day: 0 * decay + tss * (1 - decay)
        let atlDecay = Foundation.exp(-1.0 / 7.0)
        let expectedATL = tss * (1.0 - atlDecay)
        #expect(abs(e.atl - expectedATL) < 1e-10)
        // CTL similarly
        let ctlDecay = Foundation.exp(-1.0 / 42.0)
        let expectedCTL = tss * (1.0 - ctlDecay)
        #expect(abs(e.ctl - expectedCTL) < 1e-10)
        // TSB = CTL - ATL
        #expect(abs(e.tsb - (e.ctl - e.atl)) < 1e-10)
    }

    // MARK: EWA formula correctness

    @Test("ATL decay constant uses exp(-1/7)")
    func atlDecayConstant() {
        // Run two days: day1 TSS=X, day2 TSS=0. ATL on day2 = ATL_day1 * exp(-1/7).
        let tss = 80.0
        let entries = TrainingLoadModel.compute(from: [
            DailyTSS(date: "2026-01-01", tss: tss),
            DailyTSS(date: "2026-01-02", tss: 0)
        ])
        let atlDay1 = entries[0].atl
        let atlDay2 = entries[1].atl
        let expectedATL2 = atlDay1 * Foundation.exp(-1.0 / 7.0)
        #expect(abs(atlDay2 - expectedATL2) < 1e-10)
    }

    @Test("CTL decay constant uses exp(-1/42)")
    func ctlDecayConstant() {
        let tss = 80.0
        let entries = TrainingLoadModel.compute(from: [
            DailyTSS(date: "2026-01-01", tss: tss),
            DailyTSS(date: "2026-01-02", tss: 0)
        ])
        let ctlDay1 = entries[0].ctl
        let ctlDay2 = entries[1].ctl
        let expectedCTL2 = ctlDay1 * Foundation.exp(-1.0 / 42.0)
        #expect(abs(ctlDay2 - expectedCTL2) < 1e-10)
    }

    @Test("TSB equals CTL minus ATL for every entry")
    func tsbIsCtlMinusAtl() {
        let inputs = (0..<10).map { DailyTSS(date: "2026-01-\(String(format: "%02d", $0 + 1))", tss: Double($0 * 20)) }
        let entries = TrainingLoadModel.compute(from: inputs)
        for e in entries {
            #expect(abs(e.tsb - (e.ctl - e.atl)) < 1e-10)
        }
    }

    // MARK: Steady-state convergence

    @Test("ATL converges toward constant TSS after many days (7-day window)")
    func atlConvergesToConstantTSS() {
        // After N >> 7 days of constant TSS, ATL ≈ TSS
        let tss = 100.0
        let days = (0..<200).map { DailyTSS(date: "2024-01-01", tss: tss) }
        // Use distinct dates by constructing them manually
        let cal = Calendar(identifier: .gregorian)
        var fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        let start = fmt.date(from: "2024-01-01")!
        let inputs = (0..<200).map { i -> DailyTSS in
            let date = cal.date(byAdding: .day, value: i, to: start)!
            return DailyTSS(date: fmt.string(from: date), tss: tss)
        }
        let entries = TrainingLoadModel.compute(from: inputs)
        let finalATL = entries.last!.atl
        // Should be within 0.1% of tss
        #expect(abs(finalATL - tss) / tss < 0.001)
    }

    @Test("CTL converges toward constant TSS after many days (42-day window)")
    func ctlConvergesToConstantTSS() {
        var fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        let cal = Calendar(identifier: .gregorian)
        let start = fmt.date(from: "2024-01-01")!
        let tss = 75.0
        let inputs = (0..<400).map { i -> DailyTSS in
            let date = cal.date(byAdding: .day, value: i, to: start)!
            return DailyTSS(date: fmt.string(from: date), tss: tss)
        }
        let entries = TrainingLoadModel.compute(from: inputs)
        let finalCTL = entries.last!.ctl
        #expect(abs(finalCTL - tss) / tss < 0.001)
    }

    @Test("ATL responds faster than CTL")
    func atlFasterThanCtl() {
        // After a sudden high TSS day, ATL should be higher than CTL
        // (ATL has shorter window → reacts faster)
        var fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        let cal = Calendar(identifier: .gregorian)
        let start = fmt.date(from: "2026-01-01")!
        // 50 days at TSS=0, then 1 day at TSS=200
        var inputs = (0..<50).map { i -> DailyTSS in
            let date = cal.date(byAdding: .day, value: i, to: start)!
            return DailyTSS(date: fmt.string(from: date), tss: 0)
        }
        let spikeDate = cal.date(byAdding: .day, value: 50, to: start)!
        inputs.append(DailyTSS(date: fmt.string(from: spikeDate), tss: 200))

        let entries = TrainingLoadModel.compute(from: inputs)
        let last = entries.last!
        // ATL should rise more than CTL after a single high-load day
        #expect(last.atl > last.ctl)
    }

    @Test("ATL decays significantly after 7 days of zero TSS following high load")
    func atlDecaysAfterRest() {
        var fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        let cal = Calendar(identifier: .gregorian)
        let start = fmt.date(from: "2026-01-01")!
        // 1 day at TSS=200, then 7 days at TSS=0
        var inputs: [DailyTSS] = []
        let highDate = fmt.string(from: start)
        inputs.append(DailyTSS(date: highDate, tss: 200))
        for i in 1...7 {
            let date = cal.date(byAdding: .day, value: i, to: start)!
            inputs.append(DailyTSS(date: fmt.string(from: date), tss: 0))
        }
        let entries = TrainingLoadModel.compute(from: inputs)
        let atlAfterHighDay = entries[0].atl
        let atlAfter7RestDays = entries[7].atl
        // ATL should decay to less than 40% of original after 7 zero days
        // (exp(-7/7) ≈ 0.368)
        #expect(atlAfter7RestDays < atlAfterHighDay * 0.5)
    }

    // MARK: Sorting invariance

    @Test("Out-of-order input produces same result as sorted input")
    func outOfOrderInputMatchesSorted() {
        let sorted: [DailyTSS] = [
            DailyTSS(date: "2026-01-01", tss: 50),
            DailyTSS(date: "2026-01-02", tss: 80),
            DailyTSS(date: "2026-01-03", tss: 30)
        ]
        let shuffled: [DailyTSS] = [
            DailyTSS(date: "2026-01-03", tss: 30),
            DailyTSS(date: "2026-01-01", tss: 50),
            DailyTSS(date: "2026-01-02", tss: 80)
        ]

        let resultSorted   = TrainingLoadModel.compute(from: sorted)
        let resultShuffled = TrainingLoadModel.compute(from: shuffled)

        #expect(resultSorted.count == resultShuffled.count)
        for (a, b) in zip(resultSorted, resultShuffled) {
            #expect(a.date == b.date)
            #expect(abs(a.atl - b.atl) < 1e-10)
            #expect(abs(a.ctl - b.ctl) < 1e-10)
        }
    }

    // MARK: Dates preserved in output

    @Test("Output dates match input dates")
    func outputDatesMatchInput() {
        let inputs = [
            DailyTSS(date: "2026-03-10", tss: 100),
            DailyTSS(date: "2026-03-11", tss: 50)
        ]
        let entries = TrainingLoadModel.compute(from: inputs)
        #expect(entries[0].date == "2026-03-10")
        #expect(entries[1].date == "2026-03-11")
    }

    @Test("TSS values preserved in output")
    func tssValuesPreserved() {
        let inputs = [
            DailyTSS(date: "2026-01-01", tss: 42.5),
            DailyTSS(date: "2026-01-02", tss: 99.9)
        ]
        let entries = TrainingLoadModel.compute(from: inputs)
        #expect(entries[0].tss == 42.5)
        #expect(entries[1].tss == 99.9)
    }
}

// MARK: - fillGaps Tests

@Suite("TrainingLoadModel.fillGaps (via compute)")
struct FillGapsTests {

    @Test("Missing days between two dates get TSS=0")
    func missingDaysFilledWithZero() {
        let inputs = [
            DailyTSS(date: "2026-01-01", tss: 100),
            DailyTSS(date: "2026-01-04", tss: 50)  // 2 days missing in between
        ]
        let entries = TrainingLoadModel.compute(from: inputs)
        // Should have entries for Jan 1, 2, 3, 4
        #expect(entries.count == 4)
        #expect(entries[0].date == "2026-01-01")
        #expect(entries[1].date == "2026-01-02")
        #expect(entries[1].tss == 0.0)
        #expect(entries[2].date == "2026-01-03")
        #expect(entries[2].tss == 0.0)
        #expect(entries[3].date == "2026-01-04")
        #expect(entries[3].tss == 50.0)
    }

    @Test("Consecutive days produce no gap-fill entries")
    func consecutiveDaysNoGapFill() {
        let inputs = [
            DailyTSS(date: "2026-02-01", tss: 10),
            DailyTSS(date: "2026-02-02", tss: 20),
            DailyTSS(date: "2026-02-03", tss: 30)
        ]
        let entries = TrainingLoadModel.compute(from: inputs)
        #expect(entries.count == 3)
    }

    @Test("Single entry is returned unchanged (no gap fill needed)")
    func singleEntryNotFilled() {
        let entries = TrainingLoadModel.compute(from: [DailyTSS(date: "2026-05-01", tss: 60)])
        #expect(entries.count == 1)
    }

    @Test("Gap-filled zero days contribute to EWA decay correctly")
    func gapFilledDaysAffectEWA() {
        // Day1 TSS=100, then skip 6 days, Day8 TSS=0
        // The ATL on Day8 should be significantly less than ATL on Day1
        // because 6 zero days (via fill) apply exp(-1/7) decay each.
        let inputs = [
            DailyTSS(date: "2026-01-01", tss: 100),
            DailyTSS(date: "2026-01-08", tss: 0)
        ]
        let entries = TrainingLoadModel.compute(from: inputs)
        #expect(entries.count == 8)
        let atlDay1 = entries[0].atl
        let atlDay8 = entries[7].atl
        // After 7 decay steps from day1 value: atl8 ≈ atl1 * exp(-7/7) ≈ atl1 * 0.368
        #expect(atlDay8 < atlDay1 * 0.5)
    }
}

// MARK: - parseTrainingLoadCSV Tests

@Suite("parseTrainingLoadCSV")
struct ParseTrainingLoadCSVTests {

    // MARK: Happy path

    @Test("Parses minimal valid CSV")
    func parsesMinimalCSV() throws {
        let csv = """
        date,tss
        2026-01-01,100
        2026-01-02,80
        """
        let result = try parseTrainingLoadCSV(csv)
        #expect(result.count == 2)
        #expect(result[0].date == "2026-01-01")
        #expect(result[0].tss == 100)
        #expect(result[1].date == "2026-01-02")
        #expect(result[1].tss == 80)
    }

    @Test("Parses CSV with extra columns")
    func parsesCSVWithExtraColumns() throws {
        let csv = """
        date,activity,tss,notes
        2026-01-01,run,120,easy
        """
        let result = try parseTrainingLoadCSV(csv)
        #expect(result.count == 1)
        #expect(result[0].tss == 120)
    }

    @Test("Header is case-insensitive")
    func headerIsCaseInsensitive() throws {
        let csv = """
        Date,TSS
        2026-01-01,55
        """
        let result = try parseTrainingLoadCSV(csv)
        #expect(result.count == 1)
        #expect(result[0].tss == 55)
    }

    @Test("Comment lines are skipped")
    func commentLinesSkipped() throws {
        let csv = """
        # This is a comment
        date,tss
        # Another comment
        2026-01-01,70
        """
        let result = try parseTrainingLoadCSV(csv)
        #expect(result.count == 1)
        #expect(result[0].tss == 70)
    }

    @Test("Blank lines are skipped")
    func blankLinesSkipped() throws {
        let csv = "date,tss\n\n2026-01-01,90\n\n2026-01-02,45\n"
        let result = try parseTrainingLoadCSV(csv)
        #expect(result.count == 2)
    }

    @Test("Parses decimal TSS values")
    func parsesDecimalTSS() throws {
        let csv = """
        date,tss
        2026-01-01,123.45
        """
        let result = try parseTrainingLoadCSV(csv)
        #expect(result[0].tss == 123.45)
    }

    @Test("Parses zero TSS")
    func parsesZeroTSS() throws {
        let csv = """
        date,tss
        2026-01-01,0
        """
        let result = try parseTrainingLoadCSV(csv)
        #expect(result[0].tss == 0.0)
    }

    @Test("Parses negative TSS (not rejected at parse level)")
    func parsesNegativeTSS() throws {
        let csv = """
        date,tss
        2026-01-01,-10
        """
        let result = try parseTrainingLoadCSV(csv)
        #expect(result[0].tss == -10.0)
    }

    // MARK: Error cases

    @Test("Throws emptyFile for empty input")
    func throwsOnEmptyInput() {
        #expect(throws: TrainingLoadInputError.self) {
            _ = try parseTrainingLoadCSV("")
        }
    }

    @Test("Throws emptyFile when only comments present")
    func throwsOnOnlyComments() {
        #expect(throws: TrainingLoadInputError.self) {
            _ = try parseTrainingLoadCSV("# just a comment\n")
        }
    }

    @Test("Throws missingDateColumn when date column absent")
    func throwsMissingDateColumn() throws {
        let csv = "tss\n100\n"
        #expect(throws: TrainingLoadInputError.self) {
            _ = try parseTrainingLoadCSV(csv)
        }
    }

    @Test("Throws missingTSSColumn when tss column absent")
    func throwsMissingTSSColumn() throws {
        let csv = "date\n2026-01-01\n"
        #expect(throws: TrainingLoadInputError.self) {
            _ = try parseTrainingLoadCSV(csv)
        }
    }

    @Test("Throws invalidRow for non-numeric TSS value")
    func throwsInvalidRowForNonNumericTSS() {
        let csv = """
        date,tss
        2026-01-01,abc
        """
        #expect(throws: TrainingLoadInputError.self) {
            _ = try parseTrainingLoadCSV(csv)
        }
    }

    @Test("Rows with too few columns are silently skipped")
    func shortRowsSkipped() throws {
        // A row that doesn't have enough columns is skipped (not a throw)
        let csv = """
        date,tss
        2026-01-01
        2026-01-02,80
        """
        let result = try parseTrainingLoadCSV(csv)
        #expect(result.count == 1)
        #expect(result[0].date == "2026-01-02")
    }
}
