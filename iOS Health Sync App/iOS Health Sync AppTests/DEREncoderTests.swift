// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Testing
@testable import iOS_Health_Sync_App

@Test
func derEncoderSequenceEncodesCorrectly() {
    let element1 = DEREncoder.integer(1)
    let element2 = DEREncoder.integer(2)
    let result = DEREncoder.sequence([element1, element2])

    // Sequence tag is 0x30
    #expect(result[0] == 0x30)
    // Length should be sum of element lengths
    let expectedLength = element1.count + element2.count
    #expect(result[1] == UInt8(expectedLength))
    // Content should be concatenated elements
    #expect(result.suffix(from: 2) == element1 + element2)
}

@Test
func derEncoderSetEncodesCorrectly() {
    let element = DEREncoder.utf8String("test")
    let result = DEREncoder.set([element])

    // Set tag is 0x31
    #expect(result[0] == 0x31)
    #expect(result[1] == UInt8(element.count))
}

@Test
func derEncoderIntegerEncodesSmallPositiveValue() {
    let result = DEREncoder.integer(42)

    // Integer tag is 0x02
    #expect(result[0] == 0x02)
    // Length should be 1 byte
    #expect(result[1] == 0x01)
    // Value should be 42
    #expect(result[2] == 42)
}

@Test
func derEncoderIntegerEncodesLargeValue() {
    let result = DEREncoder.integer(256)

    #expect(result[0] == 0x02)
    // 256 = 0x0100, needs 2 bytes
    #expect(result[1] == 0x02)
    #expect(result[2] == 0x01)
    #expect(result[3] == 0x00)
}

@Test
func derEncoderIntegerAddsLeadingZeroForHighBit() {
    // If first byte has high bit set (>= 128), must prepend 0x00
    let bytes: [UInt8] = [0x80] // High bit set
    let result = DEREncoder.integer(bytes)

    #expect(result[0] == 0x02)
    // Should be 2 bytes: 0x00 followed by 0x80
    #expect(result[1] == 0x02)
    #expect(result[2] == 0x00)
    #expect(result[3] == 0x80)
}

@Test
func derEncoderIntegerNoLeadingZeroIfNotNeeded() {
    let bytes: [UInt8] = [0x7F] // High bit not set
    let result = DEREncoder.integer(bytes)

    #expect(result[0] == 0x02)
    #expect(result[1] == 0x01)
    #expect(result[2] == 0x7F)
}

@Test
func derEncoderObjectIdentifierEncodesShortOID() {
    // OID 1.2 encodes as: first byte = 1*40 + 2 = 42
    let result = DEREncoder.objectIdentifier([1, 2])

    #expect(result[0] == 0x06) // OID tag
    #expect(result[1] == 0x01) // 1 byte length
    #expect(result[2] == 42)   // 1*40 + 2
}

@Test
func derEncoderObjectIdentifierEncodesECDSAWithSHA256() {
    // OID 1.2.840.10045.4.3.2 (ecdsa-with-SHA256)
    let result = DEREncoder.objectIdentifier([1, 2, 840, 10045, 4, 3, 2])

    #expect(result[0] == 0x06) // OID tag
    // First two components: 1*40 + 2 = 42 = 0x2A
    // 840 encoded in base-128 multibyte
    // 10045 encoded in base-128 multibyte
    // etc.
    #expect(result.count > 3) // Should have multiple bytes
}

@Test
func derEncoderObjectIdentifierEncodesLargeComponents() {
    // Component 840 requires base-128 encoding: 0x86, 0x48
    // Component 10045 requires base-128 encoding: 0xCE, 0x3D
    let oid: [UInt64] = [1, 2, 840, 10045]
    let result = DEREncoder.objectIdentifier(oid)

    #expect(result[0] == 0x06)
    // Verify it doesn't crash and produces valid output
    #expect(result.count >= 2)
}

@Test
func derEncoderObjectIdentifierEmptyReturnsEmpty() {
    let result = DEREncoder.objectIdentifier([])
    #expect(result.isEmpty)

    let single = DEREncoder.objectIdentifier([1])
    #expect(single.isEmpty)
}

@Test
func derEncoderPrintableStringEncodesCorrectly() {
    let result = DEREncoder.printableString("test")

    #expect(result[0] == 0x13) // PrintableString tag
    #expect(result[1] == 4)    // "test" is 4 bytes
    #expect(String(data: result.suffix(from: 2), encoding: .utf8) == "test")
}

@Test
func derEncoderUTF8StringEncodesCorrectly() {
    let result = DEREncoder.utf8String("Hello")

    #expect(result[0] == 0x0C) // UTF8String tag
    #expect(result[1] == 5)    // "Hello" is 5 bytes
    #expect(String(data: result.suffix(from: 2), encoding: .utf8) == "Hello")
}

@Test
func derEncoderUTF8StringEncodesUnicode() {
    let result = DEREncoder.utf8String("Olá")

    #expect(result[0] == 0x0C)
    // "Olá" is 4 bytes in UTF-8 (O, l, á = 0xC3 0xA1)
    #expect(result[1] == 4)
}

@Test
func derEncoderUTCTimeEncodesCorrectly() {
    let components = DateComponents(
        timeZone: TimeZone(secondsFromGMT: 0),
        year: 2025,
        month: 6,
        day: 15,
        hour: 12,
        minute: 30,
        second: 45
    )
    let date = Calendar(identifier: .gregorian).date(from: components)!
    let result = DEREncoder.utcTime(date)

    #expect(result[0] == 0x17) // UTCTime tag
    // UTCTime format: YYMMDDHHmmssZ
    // "250615123045Z" = 13 bytes
    #expect(result[1] == 13)
    let timeString = String(data: result.suffix(from: 2), encoding: .utf8)
    #expect(timeString == "250615123045Z")
}

@Test
func derEncoderUTCTimeProduces24HourFormatRegardlessOfLocale() {
    // Regression test: without en_US_POSIX locale, DateFormatter may produce
    // 12-hour times with AM/PM on non-English locales (e.g. Italian), breaking
    // DER certificate parsing. UTCTime must always be "YYMMDDHHmmssZ".
    let components = DateComponents(
        timeZone: TimeZone(secondsFromGMT: 0),
        year: 2025,
        month: 6,
        day: 15,
        hour: 22,  // 10 PM — this is the case that breaks without POSIX locale
        minute: 30,
        second: 45
    )
    let date = Calendar(identifier: .gregorian).date(from: components)!
    let result = DEREncoder.utcTime(date)
    let timeString = String(data: result.suffix(from: 2), encoding: .utf8)

    // Must be 24-hour format, no AM/PM, exactly 13 chars
    #expect(timeString == "250615223045Z")
    #expect(result[1] == 13) // UTCTime is always 13 bytes
}

@Test
func derEncoderBitStringEncodesCorrectly() {
    let data = Data([0x01, 0x02, 0x03])
    let result = DEREncoder.bitString(data)

    #expect(result[0] == 0x03) // BitString tag
    // Content is: 0x00 (unused bits) + original data = 4 bytes
    #expect(result[1] == 4)
    #expect(result[2] == 0x00) // Unused bits indicator
    #expect(result[3] == 0x01)
    #expect(result[4] == 0x02)
    #expect(result[5] == 0x03)
}

@Test
func derEncoderNullEncodesCorrectly() {
    let result = DEREncoder.null()

    #expect(result.count == 2)
    #expect(result[0] == 0x05) // NULL tag
    #expect(result[1] == 0x00) // Zero length
}

@Test
func derEncoderContextSpecificEncodesCorrectly() {
    let content = DEREncoder.integer(2)
    let result = DEREncoder.contextSpecific(0, content: content)

    // Context-specific tag 0 = 0xA0
    #expect(result[0] == 0xA0)
    #expect(result[1] == UInt8(content.count))
}

@Test
func derEncoderContextSpecificWithTag3() {
    let content = DEREncoder.utf8String("test")
    let result = DEREncoder.contextSpecific(3, content: content)

    #expect(result[0] == 0xA3) // 0xA0 | 3
}

@Test
func derEncoderLongFormLengthEncodesCorrectly() {
    // Create content longer than 127 bytes
    let longString = String(repeating: "x", count: 200)
    let result = DEREncoder.utf8String(longString)

    #expect(result[0] == 0x0C)
    // Length >= 128 uses long form: 0x81 followed by actual length
    #expect(result[1] == 0x81) // Long form indicator for 1-byte length
    #expect(result[2] == 200)  // Actual length
}

@Test
func derEncoderVeryLongFormLengthEncodesCorrectly() {
    // Create content longer than 255 bytes
    let veryLongString = String(repeating: "x", count: 300)
    let result = DEREncoder.utf8String(veryLongString)

    #expect(result[0] == 0x0C)
    // Length > 255 uses 2-byte length: 0x82 followed by 2 bytes
    #expect(result[1] == 0x82) // Long form indicator for 2-byte length
    #expect(result[2] == 0x01) // 300 = 0x012C (high byte)
    #expect(result[3] == 0x2C) // 300 = 0x012C (low byte)
}

@Test
func derEncoderNestedSequencesWork() {
    let inner = DEREncoder.sequence([
        DEREncoder.integer(1),
        DEREncoder.integer(2)
    ])
    let outer = DEREncoder.sequence([inner, DEREncoder.integer(3)])

    #expect(outer[0] == 0x30)
    // Should not crash and produce valid nested structure
    #expect(outer.count > inner.count)
}

@Test
func derEncoderEmptySequence() {
    let result = DEREncoder.sequence([])

    #expect(result[0] == 0x30)
    #expect(result[1] == 0x00) // Zero length
    #expect(result.count == 2)
}

@Test
func derEncoderBase128EncodesMaxUInt64Component() {
    // Test with a large OID component to verify base-128 encoding
    // 2^63 - 1 = 9223372036854775807
    let oid: [UInt64] = [2, 1, UInt64.max / 2]
    let result = DEREncoder.objectIdentifier(oid)

    // Should not crash and produce valid output
    #expect(result[0] == 0x06)
    #expect(result.count > 2)
}

@Test
func derEncoderIntegerZeroEncodesCorrectly() {
    // Encoding 0 should still produce valid output
    let bytes: [UInt8] = [0x00]
    let result = DEREncoder.integer(bytes)

    #expect(result[0] == 0x02)
    #expect(result[1] == 0x01)
    #expect(result[2] == 0x00)
}

@Test
func derEncoderCertificateStructureValid() {
    // Test that a basic certificate structure can be built
    let version = DEREncoder.contextSpecific(0, content: DEREncoder.integer(2))
    let serial = DEREncoder.integer(12345)
    let algorithm = DEREncoder.sequence([
        DEREncoder.objectIdentifier([1, 2, 840, 10045, 4, 3, 2]),
        DEREncoder.null()
    ])
    let name = DEREncoder.sequence([
        DEREncoder.set([
            DEREncoder.sequence([
                DEREncoder.objectIdentifier([2, 5, 4, 3]),
                DEREncoder.utf8String("Test")
            ])
        ])
    ])
    let validity = DEREncoder.sequence([
        DEREncoder.utcTime(Date()),
        DEREncoder.utcTime(Date().addingTimeInterval(86400))
    ])

    let tbs = DEREncoder.sequence([
        version,
        serial,
        algorithm,
        name,
        validity,
        name,
        DEREncoder.sequence([algorithm, DEREncoder.bitString(Data(repeating: 0, count: 65))])
    ])

    #expect(tbs[0] == 0x30)
    #expect(tbs.count > 50)
}
