// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation

struct HTTPRequest {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data
}

struct HTTPResponse {
    let statusCode: Int
    let reason: String
    let headers: [String: String]
    let body: Data

    func toData() -> Data {
        var response = "HTTP/1.1 \(statusCode) \(reason)\r\n"
        for (key, value) in headers {
            response += "\(key): \(value)\r\n"
        }
        response += "Content-Length: \(body.count)\r\n"
        response += "\r\n"
        var data = Data(response.utf8)
        data.append(body)
        return data
    }

    static func json(statusCode: Int, reason: String = "OK", body: Encodable) -> HTTPResponse {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = (try? encoder.encode(AnyEncodable(body))) ?? Data("{}".utf8)
        return HTTPResponse(
            statusCode: statusCode,
            reason: reason,
            headers: ["Content-Type": "application/json"],
            body: data
        )
    }

    static func plain(statusCode: Int, reason: String, message: String) -> HTTPResponse {
        HTTPResponse(
            statusCode: statusCode,
            reason: reason,
            headers: ["Content-Type": "text/plain"],
            body: Data(message.utf8)
        )
    }
}

enum HTTPParseError: Error {
    case invalidRequest
    case incomplete
    case bodyTooLarge
}

struct AnyEncodable: Encodable {
    private let encodeBlock: (Encoder) throws -> Void

    init(_ encodable: Encodable) {
        self.encodeBlock = encodable.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeBlock(encoder)
    }
}
