// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation

enum DEREncoder {
    static func sequence(_ elements: [Data]) -> Data {
        wrap(tag: 0x30, content: elements.joined())
    }

    static func set(_ elements: [Data]) -> Data {
        wrap(tag: 0x31, content: elements.joined())
    }

    static func integer(_ bytes: [UInt8]) -> Data {
        var value = bytes
        if let first = value.first, first & 0x80 != 0 {
            value.insert(0x00, at: 0)
        }
        return wrap(tag: 0x02, content: Data(value))
    }

    static func integer(_ value: Int) -> Data {
        var bytes = [UInt8]()
        var v = value
        repeat {
            bytes.insert(UInt8(v & 0xFF), at: 0)
            v >>= 8
        } while v > 0
        return integer(bytes)
    }

    static func objectIdentifier(_ oid: [UInt64]) -> Data {
        guard oid.count >= 2 else { return Data() }
        var bytes = [UInt8]()
        bytes.append(UInt8(oid[0] * 40 + oid[1]))
        for component in oid.dropFirst(2) {
            bytes.append(contentsOf: encodeBase128(component))
        }
        return wrap(tag: 0x06, content: Data(bytes))
    }

    static func printableString(_ value: String) -> Data {
        wrap(tag: 0x13, content: Data(value.utf8))
    }

    static func utf8String(_ value: String) -> Data {
        wrap(tag: 0x0C, content: Data(value.utf8))
    }

    static func utcTime(_ date: Date) -> Data {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyMMddHHmmss'Z'"
        let value = formatter.string(from: date)
        return wrap(tag: 0x17, content: Data(value.utf8))
    }

    static func bitString(_ data: Data) -> Data {
        var content = Data([0x00])
        content.append(data)
        return wrap(tag: 0x03, content: content)
    }

    static func null() -> Data {
        wrap(tag: 0x05, content: Data())
    }

    static func contextSpecific(_ tag: UInt8, content: Data) -> Data {
        wrap(tag: 0xA0 | tag, content: content)
    }

    private static func wrap(tag: UInt8, content: Data) -> Data {
        var data = Data([tag])
        data.append(contentsOf: encodeLength(content.count))
        data.append(content)
        return data
    }

    private static func encodeLength(_ length: Int) -> [UInt8] {
        if length < 128 {
            return [UInt8(length)]
        }
        var bytes = [UInt8]()
        var value = length
        while value > 0 {
            bytes.insert(UInt8(value & 0xFF), at: 0)
            value >>= 8
        }
        var result = [UInt8(0x80 | UInt8(bytes.count))]
        result.append(contentsOf: bytes)
        return result
    }

    private static func encodeBase128(_ value: UInt64) -> [UInt8] {
        var bytes = [UInt8]()
        var v = value
        repeat {
            bytes.insert(UInt8(v & 0x7F), at: 0)
            v >>= 7
        } while v > 0
        for i in 0..<(bytes.count - 1) {
            bytes[i] |= 0x80
        }
        return bytes
    }
}

private extension Array where Element == Data {
    func joined() -> Data {
        reduce(into: Data()) { $0.append($1) }
    }
}
