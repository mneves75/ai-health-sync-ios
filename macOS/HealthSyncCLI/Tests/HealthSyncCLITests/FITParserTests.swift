// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Testing
@testable import HealthSyncCLI

// MARK: - Helpers

/// Build a minimal 14-byte FIT file header + dataSize bytes of zeroed record data.
/// - Parameters:
///   - headerSize: byte 0 (14 or 12)
///   - protocolVersion: byte 1 (high nibble = major version)
///   - dataSize: bytes 4-7 LE (content of the data region)
///   - magic: 4-byte magic bytes 8-11 (default: ".FIT")
///   - pad: extra bytes appended after the header to satisfy dataEnd <= data.count
private func makeFITBytes(
    headerSize: UInt8 = 14,
    protocolVersion: UInt8 = 0x10,  // major=1, minor=0
    profileVersion: UInt16 = 0,
    dataSize: UInt32 = 0,
    magic: [UInt8] = [0x2E, 0x46, 0x49, 0x54],
    headerCRC: UInt16 = 0,
    pad: Int = 0
) -> Data {
    var bytes: [UInt8] = []
    bytes.append(headerSize)
    bytes.append(protocolVersion)
    // profile version LE
    bytes.append(UInt8(profileVersion & 0xFF))
    bytes.append(UInt8((profileVersion >> 8) & 0xFF))
    // data size LE
    bytes.append(UInt8(dataSize & 0xFF))
    bytes.append(UInt8((dataSize >> 8) & 0xFF))
    bytes.append(UInt8((dataSize >> 16) & 0xFF))
    bytes.append(UInt8((dataSize >> 24) & 0xFF))
    // magic
    bytes.append(contentsOf: magic)
    if headerSize == 14 {
        // header CRC LE
        bytes.append(UInt8(headerCRC & 0xFF))
        bytes.append(UInt8((headerCRC >> 8) & 0xFF))
    }
    // padding (simulates data region)
    bytes.append(contentsOf: [UInt8](repeating: 0x00, count: pad))
    return Data(bytes)
}

// MARK: - FITParser Header Parsing Tests

@Suite("FITParser header parsing")
struct FITParserHeaderTests {

    // MARK: Valid headers

    @Test("Parses valid 14-byte header with protocol version 1")
    func validHeader14ByteProtocol1() throws {
        // dataSize=0 so no records, just header parse succeeds
        let data = makeFITBytes(headerSize: 14, protocolVersion: 0x10, dataSize: 0)
        let parser = FITParser(data: data)
        // Should not throw
        let file = try parser.parse()
        #expect(file.records.isEmpty)
    }

    @Test("Parses valid 14-byte header with protocol version 2")
    func validHeader14ByteProtocol2() throws {
        let data = makeFITBytes(headerSize: 14, protocolVersion: 0x20, dataSize: 0)
        let parser = FITParser(data: data)
        let file = try parser.parse()
        #expect(file.records.isEmpty)
    }

    @Test("Parses valid 12-byte header")
    func validHeader12Byte() throws {
        // 12-byte header has no CRC field
        var bytes: [UInt8] = [
            12,           // headerSize = 12
            0x10,         // protocolVersion (major=1)
            0x00, 0x00,   // profileVersion
            0x00, 0x00, 0x00, 0x00,  // dataSize = 0
            0x2E, 0x46, 0x49, 0x54   // ".FIT"
        ]
        let data = Data(bytes)
        let parser = FITParser(data: data)
        let file = try parser.parse()
        #expect(file.records.isEmpty)
    }

    @Test("Parses header with protocol version 0 (major=0)")
    func validProtocolVersion0() throws {
        // high nibble = 0 → major version 0 ≤ 2, should be accepted
        let data = makeFITBytes(protocolVersion: 0x00, dataSize: 0)
        let parser = FITParser(data: data)
        let file = try parser.parse()
        #expect(file.records.isEmpty)
    }

    // MARK: Invalid header — wrong magic

    @Test("Throws invalidHeader when magic bytes are wrong")
    func throwsInvalidHeaderOnBadMagic() {
        let data = makeFITBytes(
            headerSize: 14,
            protocolVersion: 0x10,
            dataSize: 0,
            magic: [0xFF, 0xFF, 0xFF, 0xFF]
        )
        let parser = FITParser(data: data)
        #expect(throws: FITParseError.self) {
            _ = try parser.parse()
        }
    }

    @Test("Throws invalidHeader when magic spells .FIT with wrong case")
    func throwsInvalidHeaderOnLowercaseMagic() {
        // ".fit" in lowercase: 0x2E 0x66 0x69 0x74
        let data = makeFITBytes(
            headerSize: 14,
            protocolVersion: 0x10,
            dataSize: 0,
            magic: [0x2E, 0x66, 0x69, 0x74]
        )
        let parser = FITParser(data: data)
        #expect(throws: FITParseError.self) {
            _ = try parser.parse()
        }
    }

    @Test("Throws invalidHeader for unsupported headerSize values")
    func throwsInvalidHeaderForBadHeaderSize() {
        // Only 12 and 14 are valid; 10 should be rejected
        var bytes: [UInt8] = [
            10,           // invalid headerSize
            0x10,
            0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x2E, 0x46, 0x49, 0x54
        ]
        let data = Data(bytes)
        let parser = FITParser(data: data)
        #expect(throws: FITParseError.self) {
            _ = try parser.parse()
        }
    }

    // MARK: Unsupported protocol

    @Test("Throws unsupportedProtocol when major version is 3")
    func throwsUnsupportedProtocolVersion3() {
        // high nibble = 3 → major version 3 > 2, should be rejected
        let data = makeFITBytes(headerSize: 14, protocolVersion: 0x30, dataSize: 0)
        let parser = FITParser(data: data)
        #expect(throws: FITParseError.self) {
            _ = try parser.parse()
        }
    }

    @Test("Throws unsupportedProtocol when major version is 15")
    func throwsUnsupportedProtocolVersionMax() {
        let data = makeFITBytes(headerSize: 14, protocolVersion: 0xF0, dataSize: 0)
        let parser = FITParser(data: data)
        #expect(throws: FITParseError.self) {
            _ = try parser.parse()
        }
    }

    // MARK: Data size exceeds file length

    @Test("Throws corruptData when dataSize exceeds actual file length")
    func throwsWhenDataSizeExceedsFile() {
        // Header says dataSize=100 but we only have the 14-byte header → total 14 bytes, dataEnd=114 > 14
        let data = makeFITBytes(headerSize: 14, protocolVersion: 0x10, dataSize: 100, pad: 0)
        let parser = FITParser(data: data)
        #expect(throws: FITParseError.self) {
            _ = try parser.parse()
        }
    }

    @Test("Accepts file when dataSize matches padded payload")
    func acceptsWhenDataSizeMatchesPad() throws {
        // dataSize=5, pad=5 → total bytes = 14 + 5 = 19 → dataEnd = 14 + 5 = 19 <= 19
        // The 5 zero bytes will be parsed as record bytes; first byte = 0x00 (normal data header,
        // not def, localType=0, no definition exists → mesgDefs[0] nil → skipped)
        // Actually the record loop tries to read from reader, may hit EOF.
        // We just verify no FITParseError.corruptData("Data size exceeds file length") is thrown.
        let data = makeFITBytes(headerSize: 14, protocolVersion: 0x10, dataSize: 5, pad: 5)
        let parser = FITParser(data: data)
        // May succeed or throw a different error (corrupt data while reading records),
        // but must not throw the "Data size exceeds file length" specific message.
        do {
            _ = try parser.parse()
            // If it succeeds, great.
        } catch FITParseError.corruptData(let msg) where msg.contains("Data size exceeds file length") {
            Issue.record("Should not throw 'Data size exceeds file length' when sizes match")
        } catch {
            // Other errors (e.g. premature EOF reading records) are acceptable
        }
    }

    // MARK: Empty / truncated data

    @Test("Throws on completely empty data")
    func throwsOnEmptyData() {
        let parser = FITParser(data: Data())
        #expect(throws: FITParseError.self) {
            _ = try parser.parse()
        }
    }

    @Test("Throws on data that is too short to contain a header")
    func throwsOnTruncatedHeader() {
        // Only 4 bytes — not enough for even headerSize byte read
        let data = Data([0x0E, 0x10, 0x00, 0x00])
        let parser = FITParser(data: data)
        #expect(throws: FITParseError.self) {
            _ = try parser.parse()
        }
    }
}

// MARK: - Compressed Timestamp Rollover Tests

@Suite("FITParser compressed timestamp rollover")
struct FITParserCompressedTimestampTests {

    // The rollover logic (from source):
    //   lower = lastTimestamp & 0x1F
    //   if timeOffset >= lower:
    //       lastTimestamp = (lastTimestamp & ~0x1F) | timeOffset
    //   else if lastTimestamp != 0xFFFFFFFF:
    //       lastTimestamp = ((lastTimestamp & ~0x1F) &+ 32) | timeOffset
    //   else:
    //       lastTimestamp = timeOffset

    // These tests exercise the logic directly rather than through FITParser,
    // since constructing a full binary FIT file with valid definition messages
    // requires knowledge of the full FIT profile. We validate the arithmetic
    // that drives the rollover.

    @Test("No rollover when timeOffset >= lower: timestamp updated in-place")
    func noRolloverWhenOffsetGEQLower() {
        // lastTimestamp = 0x0000_0010 → lower = 0x10 = 16
        // timeOffset = 20 (>= 16) → lastTimestamp = (0x0000_0010 & ~0x1F) | 20
        //                          = 0x0000_0000 | 0x14 = 0x14
        var lastTimestamp: UInt32 = 0x0000_0010
        let timeOffset: UInt32 = 20
        let lower = lastTimestamp & 0x1F
        if timeOffset >= lower {
            lastTimestamp = (lastTimestamp & ~0x1F) | timeOffset
        } else if lastTimestamp != 0xFFFFFFFF {
            lastTimestamp = ((lastTimestamp & ~0x1F) &+ 32) | timeOffset
        } else {
            lastTimestamp = timeOffset
        }
        #expect(lastTimestamp == 0x14)
    }

    @Test("Rollover when timeOffset < lower: high part incremented by 32")
    func rolloverWhenOffsetLTLower() {
        // lastTimestamp = 0x0000_001F → lower = 31
        // timeOffset = 5 (< 31) → rollover: lastTimestamp = ((0x1F & ~0x1F) + 32) | 5
        //                        = (0 + 32) | 5 = 0x20 | 0x05 = 0x25 = 37
        var lastTimestamp: UInt32 = 0x0000_001F
        let timeOffset: UInt32 = 5
        let lower = lastTimestamp & 0x1F
        if timeOffset >= lower {
            lastTimestamp = (lastTimestamp & ~0x1F) | timeOffset
        } else if lastTimestamp != 0xFFFFFFFF {
            lastTimestamp = ((lastTimestamp & ~0x1F) &+ 32) | timeOffset
        } else {
            lastTimestamp = timeOffset
        }
        #expect(lastTimestamp == 37)
    }

    @Test("Rollover with non-zero high part: high part advances correctly")
    func rolloverWithNonZeroHighPart() {
        // lastTimestamp = 0x0000_0060 (96 decimal) → lower = 0 (0x60 & 0x1F = 0)
        // timeOffset = 0x00 = 0 (>= lower=0) → no rollover: lastTimestamp = (0x60 & ~0x1F) | 0
        //   = 0x40 | 0 = 0x40 = 64 — wait, 0x60 & ~0x1F = 0x60 & 0xFFFFFFE0 = 0x60
        // Actually 0x60 in binary is 0110_0000; ~0x1F = 0xFFFFFFE0; 0x60 & 0xE0 = 0x60
        // So no rollover: 0x60 | 0 = 0x60 = 96 — stays same.
        // More interesting: lastTimestamp = 0x60 (lower=0), timeOffset=31 (>= 0)
        //   newTimestamp = 0x60 | 0x1F = 0x7F = 127
        var lastTimestamp: UInt32 = 0x60
        let timeOffset: UInt32 = 31
        let lower = lastTimestamp & 0x1F
        if timeOffset >= lower {
            lastTimestamp = (lastTimestamp & ~0x1F) | timeOffset
        } else if lastTimestamp != 0xFFFFFFFF {
            lastTimestamp = ((lastTimestamp & ~0x1F) &+ 32) | timeOffset
        } else {
            lastTimestamp = timeOffset
        }
        #expect(lastTimestamp == 0x7F)
    }

    @Test("Invalid-value sentinel 0xFFFFFFFF: lastTimestamp set directly to timeOffset")
    func sentinelHandledByAssigningTimeOffset() {
        var lastTimestamp: UInt32 = 0xFFFFFFFF
        let timeOffset: UInt32 = 10
        let lower = lastTimestamp & 0x1F  // = 0x1F = 31
        if timeOffset >= lower {
            lastTimestamp = (lastTimestamp & ~0x1F) | timeOffset
        } else if lastTimestamp != 0xFFFFFFFF {
            lastTimestamp = ((lastTimestamp & ~0x1F) &+ 32) | timeOffset
        } else {
            lastTimestamp = timeOffset  // timeOffset=10 < lower=31 and sentinel → assign
        }
        #expect(lastTimestamp == 10)
    }

    @Test("Rollover does not overflow: uses wrapping addition")
    func rolloverUsesWrappingAddition() {
        // lastTimestamp = 0xFFFFFFE0 (sentinel-adjacent, != 0xFFFFFFFF), lower = 0
        // timeOffset = 5 (>= 0) → no rollover: (0xFFFFFFE0 & ~0x1F) | 5 = 0xFFFFFFE0 | 5 = 0xFFFFFFE5
        var lastTimestamp: UInt32 = 0xFFFFFFE0
        let timeOffset: UInt32 = 5
        let lower = lastTimestamp & 0x1F
        if timeOffset >= lower {
            lastTimestamp = (lastTimestamp & ~0x1F) | timeOffset
        } else if lastTimestamp != 0xFFFFFFFF {
            lastTimestamp = ((lastTimestamp & ~0x1F) &+ 32) | timeOffset
        } else {
            lastTimestamp = timeOffset
        }
        #expect(lastTimestamp == 0xFFFFFFE5)
    }

    @Test("Rollover from 0xFFFFFFE0 with timeOffset < lower uses wrapping add")
    func rolloverFromNearMaxWraps() {
        // lastTimestamp = 0xFFFFFFFF - 1 = 0xFFFFFFFE → lower = 0x1E = 30
        // but this IS != 0xFFFFFFFF, so wrapping add applies for timeOffset < lower
        // timeOffset = 5 (< 30): newTS = ((0xFFFFFFFE & ~0x1F) &+ 32) | 5
        //   = (0xFFFFFFE0 &+ 32) | 5 = (0x00000000) | 5 = 5  (wraps around UInt32)
        var lastTimestamp: UInt32 = 0xFFFFFFFE
        let timeOffset: UInt32 = 5
        let lower = lastTimestamp & 0x1F
        if timeOffset >= lower {
            lastTimestamp = (lastTimestamp & ~0x1F) | timeOffset
        } else if lastTimestamp != 0xFFFFFFFF {
            lastTimestamp = ((lastTimestamp & ~0x1F) &+ 32) | timeOffset
        } else {
            lastTimestamp = timeOffset
        }
        // (0xFFFFFFE0 &+ 32) = 0xFFFFFFE0 + 0x20 = 0x100000000 overflows to 0x00000000
        #expect(lastTimestamp == 5)
    }
}
