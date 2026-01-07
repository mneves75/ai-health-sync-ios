#!/usr/bin/env swift -parse-as-library
// Example 4: Modern Swift Networking
//
// This example demonstrates modern Swift networking using URLSession
// with async/await and proper error handling.
// Run it with: swift 04-networking.swift
//
// Prerequisites: Swift 5.5+ (included with Xcode 13+)

import Foundation

// MARK: - 1. Networking Errors

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .noData:
            return "No data received from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - 2. API Response Models

struct HealthDataResponse: Codable {
    let success: Bool
    let samples: [HealthSample]
    let totalCount: Int
}

struct HealthSample: Codable, Sendable {
    let id: String
    let type: String
    let value: Double
    let unit: String
    let timestamp: Date
}

struct ErrorResponse: Codable {
    let error: String
    let message: String
}

// MARK: - 3. Network Manager (Actor-based)

/// Thread-safe network manager using Swift 6 actors
actor NetworkManager {
    private let session: URLSession
    private let baseURL: String

    init(baseURL: String = "https://api.example.com") {
        self.baseURL = baseURL

        // Configure session with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: config)
    }

    /// Generic fetch method with proper error handling
    func fetch<T: Decodable>(
        endpoint: String,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        print("  📡 Fetching: \(url.absoluteString)")

        do {
            let (data, response) = try await session.data(for: request)

            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                print("  📊 Status: \(httpResponse.statusCode)")

                guard (200...299).contains(httpResponse.statusCode) else {
                    // Try to parse error response
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NetworkError.httpError(statusCode: httpResponse.statusCode)
                    }
                    throw NetworkError.httpError(statusCode: httpResponse.statusCode)
                }
            }

            // Decode response
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                print("  ✅ Success: decoded response")
                return decoded
            } catch {
                throw NetworkError.decodingError(error)
            }

        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
    }

    /// POST request with JSON body
    func post<T: Encodable, U: Decodable>(
        endpoint: String,
        body: T,
        responseType: U.Type
    ) async throws -> U {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Encode body
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw NetworkError.networkError(error)
        }

        print("  📤 POST: \(url.absoluteString)")

        do {
            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("  📊 Status: \(httpResponse.statusCode)")

                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.httpError(statusCode: httpResponse.statusCode)
                }
            }

            let decoded = try JSONDecoder().decode(U.self, from: data)
            print("  ✅ Success: decoded response")
            return decoded

        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
    }
}

// MARK: - 4. Mock API Handler

/// Simulates API calls without making real network requests
actor MockAPIHandler {
    func fetchHealthData() async throws -> HealthDataResponse {
        print("  📡 Simulating API call...")

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Simulate random failures
        let success = Bool.random()
        guard success else {
            throw NetworkError.httpError(statusCode: 500)
        }

        // Return mock data
        let samples = [
            HealthSample(id: "1", type: "steps", value: 10000, unit: "count", timestamp: Date()),
            HealthSample(id: "2", type: "heartRate", value: 72, unit: "bpm", timestamp: Date()),
            HealthSample(id: "3", type: "sleep", value: 7.5, unit: "hours", timestamp: Date())
        ]

        return HealthDataResponse(
            success: true,
            samples: samples,
            totalCount: samples.count
        )
    }

    func postData(sample: HealthSample) async throws -> HealthSample {
        print("  📤 Simulating POST request...")

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Simulate random failures
        let success = Bool.random()
        guard success else {
            throw NetworkError.httpError(statusCode: 400)
        }

        print("  ✅ Sample posted successfully")
        return sample
    }
}

// MARK: - 5. Main Execution

@main
struct NetworkingExample {
    static func main() async {
        print("=== Swift Networking Examples ===\n")

        // Example 1: Mock API call (works without network)
        print("1. Mock API Handler:")
        let mockAPI = MockAPIHandler()

        do {
            let healthData = try await mockAPI.fetchHealthData()
            print("  ✅ Received \(healthData.totalCount) samples:")
            for sample in healthData.samples {
                print("    - \(sample.type): \(sample.value) \(sample.unit)")
            }
        } catch {
            print("  ❌ Error: \(error.localizedDescription)")
        }
        print()

        // Example 2: Network manager structure
        print("2. Network Manager Structure:")
        print("  The NetworkManager actor provides:")
        print("    • Thread-safe networking operations")
        print("    • Generic fetch<T>() and post<T, U>() methods")
        print("    • Automatic error handling and decoding")
        print("    • Configurable timeouts")
        print("    • Proper HTTP status code checking")
        print()

        // Example 3: Error handling demonstration
        print("3. Error Handling:")
        print("  NetworkError enum provides:")
        print("    • invalidURL - Malformed URLs")
        print("    • noData - Empty responses")
        print("    • httpError(statusCode) - HTTP status errors")
        print("    • decodingError(Error) - JSON parsing failures")
        print("    • networkError(Error) - Network connectivity issues")
        print()

        print("✅ Examples completed!")
        print("\nKey Takeaways:")
        print("  • Use async/await for modern, readable networking code")
        print("  • Create typed models (Codable) for request/response data")
        print("  • Use actors to make network operations thread-safe")
        print("  • Implement proper error handling with custom error types")
        print("  • Always validate HTTP status codes")
        print("  • Configure URLSession with appropriate timeouts")
        print("  • For the iOS Health Sync app, use mTLS for secure connections")
    }
}
