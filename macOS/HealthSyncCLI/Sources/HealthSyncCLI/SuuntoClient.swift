// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - DTOs

struct SuuntoWorkout: Encodable {
    let workoutKey: String
    let workoutName: String?
    let workoutDate: String
    let totalTimeSec: Double?
    let totalDistanceM: Double?
    let totalCalories: Int?
    let heartRateAvg: Int?
    let heartRateMax: Int?
    let epoc: Double?
    let trainingLoad: Double?
    let activityId: Int?
}

// MARK: - Client

private let apiBase = "https://cloudapi.suunto.com/v2"

/// Fetches workouts from the Suunto Sports Tracker API.
/// Paginates automatically using limit/offset until the date range is exhausted.
func suuntoFetchWorkouts(
    startDate: Date,
    endDate: Date,
    accessToken: String
) async throws -> [SuuntoWorkout] {

    var results: [SuuntoWorkout] = []
    let limit     = 100
    var offset    = 0

    let isoFormatter = ISO8601DateFormatter()

    repeat {
        var comps    = URLComponents(string: "\(apiBase)/workouts")!
        comps.queryItems = [
            URLQueryItem(name: "since",  value: isoFormatter.string(from: startDate)),
            URLQueryItem(name: "until",  value: isoFormatter.string(from: endDate)),
            URLQueryItem(name: "limit",  value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw SuuntoError.apiError(status, String(data: data, encoding: .utf8) ?? "")
        }

        let page = try parseWorkoutsPage(data)
        results.append(contentsOf: page.workouts)
        offset += page.workouts.count

        if page.workouts.count < limit { break }
    } while true

    return results
}

// MARK: - Internal parsing

private struct WorkoutPage {
    let workouts: [SuuntoWorkout]
}

private func parseWorkoutsPage(_ data: Data) throws -> WorkoutPage {
    // Use flexible JSON parsing to handle optional fields gracefully
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let payload = json["payload"] as? [[String: Any]] else {
        return WorkoutPage(workouts: [])
    }

    let workouts = payload.compactMap { raw -> SuuntoWorkout? in
        guard let key  = raw["workoutKey"] as? String,
              let date = raw["workoutDate"] as? String else { return nil }
        return SuuntoWorkout(
            workoutKey:      key,
            workoutName:     raw["workoutName"] as? String,
            workoutDate:     date,
            totalTimeSec:    raw["totalTime"] as? Double,
            totalDistanceM:  raw["totalDistance"] as? Double,
            totalCalories:   raw["totalCalories"] as? Int,
            heartRateAvg:    raw["heartRateAvg"] as? Int,
            heartRateMax:    raw["heartRateMax"] as? Int,
            epoc:            raw["epoc"] as? Double,
            trainingLoad:    raw["trainingLoad"] as? Double,
            activityId:      raw["activityId"] as? Int
        )
    }
    return WorkoutPage(workouts: workouts)
}

// MARK: - Output

func printSuuntoWorkoutsCSV(_ workouts: [SuuntoWorkout]) {
    print("workoutKey,workoutDate,workoutName,totalTimeSec,totalDistanceM,totalCalories,heartRateAvg,heartRateMax,epoc,trainingLoad,activityId")
    for w in workouts {
        func s<T>(_ v: T?) -> String { v.map { "\($0)" } ?? "" }
        print([
            w.workoutKey,
            w.workoutDate,
            w.workoutName ?? "",
            s(w.totalTimeSec),
            s(w.totalDistanceM),
            s(w.totalCalories),
            s(w.heartRateAvg),
            s(w.heartRateMax),
            s(w.epoc),
            s(w.trainingLoad),
            s(w.activityId)
        ].joined(separator: ","))
    }
}

func printSuuntoWorkoutsJSON(_ workouts: [SuuntoWorkout]) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(workouts)
    print(String(decoding: data, as: UTF8.self))
}
