// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - FIT Domain Types

/// FIT epoch: 1989-12-31 00:00:00 UTC
private let fitEpoch: TimeInterval = 631_065_600

struct FITFile: Sendable {
    let fileId: FITFileId?
    let sessions: [FITSession]
    let laps: [FITLap]
    let records: [FITRecord]
}

struct FITFileId: Sendable {
    let manufacturer: UInt16?
    let product: UInt16?
    let serialNumber: UInt32?
    let timeCreated: Date?
    let type: UInt8?
}

struct FITSession: Sendable {
    let startTime: Date?
    let timestamp: Date?
    let sport: UInt8?
    let subSport: UInt8?
    let totalElapsedSeconds: Double?
    let totalTimerSeconds: Double?
    let totalDistanceMeters: Double?
    let totalCalories: UInt16?
    let avgSpeedMetersPerSec: Double?
    let maxSpeedMetersPerSec: Double?
    let avgHeartRateBPM: UInt8?
    let maxHeartRateBPM: UInt8?
    let avgCadenceRPM: UInt8?
    let maxCadenceRPM: UInt8?
    let avgPowerWatts: UInt16?
    let maxPowerWatts: UInt16?
    let totalAscent: UInt16?
    let totalDescent: UInt16?
    // Suunto manufacturer-specific fields (nil for non-Suunto files).
    // Field numbers from community reverse-engineering of Suunto 9 / 5 FIT files.
    let suuntoEPOCml: Double?             // field 96, uint16 ÷ 10, ml O2/kg
    let suuntoRecoveryTimeHours: UInt16?  // field 87, uint16, raw hours
    let suuntoAerobicTE: Double?          // field 110, uint8 ÷ 10, range 0.0-5.0
    let suuntoAnaerobicTE: Double?        // field 111, uint8 ÷ 10, range 0.0-5.0
}

struct FITLap: Sendable {
    let startTime: Date?
    let timestamp: Date?
    let totalElapsedSeconds: Double?
    let totalTimerSeconds: Double?
    let totalDistanceMeters: Double?
    let totalCalories: UInt16?
    let avgSpeedMetersPerSec: Double?
    let maxSpeedMetersPerSec: Double?
    let avgHeartRateBPM: UInt8?
    let maxHeartRateBPM: UInt8?
    let totalAscent: UInt16?
    let totalDescent: UInt16?
}

struct FITRecord: Sendable {
    let timestamp: Date
    let positionLatDegrees: Double?
    let positionLonDegrees: Double?
    let altitudeMeters: Double?
    let heartRateBPM: UInt8?
    let cadenceRPM: UInt8?
    let speedMetersPerSec: Double?
    let powerWatts: UInt16?
    let temperatureCelsius: Int8?
    let distanceMeters: Double?
    // Suunto-specific: GPS + accelerometer fused speed (field 90, uint16 ÷ 1000 m/s)
    let suuntoFusedSpeedMps: Double?
}

// MARK: - Parser Errors

enum FITParseError: Error, LocalizedError {
    case invalidHeader
    case unsupportedProtocol(UInt8)
    case corruptData(String)
    case crcMismatch

    var errorDescription: String? {
        switch self {
        case .invalidHeader: return "Invalid FIT file header"
        case .unsupportedProtocol(let v): return "Unsupported FIT protocol version: \(v)"
        case .corruptData(let msg): return "Corrupt FIT data: \(msg)"
        case .crcMismatch: return "FIT file CRC mismatch"
        }
    }
}

// MARK: - FIT Base Types

private enum FITBaseType: UInt8 {
    case enumType   = 0x00
    case sint8      = 0x01
    case uint8      = 0x02
    case sint16     = 0x83
    case uint16     = 0x84
    case sint32     = 0x85
    case uint32     = 0x86
    case string     = 0x07
    case float32    = 0x88
    case float64    = 0x89
    case uint8z     = 0x0A
    case uint16z    = 0x8B
    case uint32z    = 0x8C
    case byte       = 0x0D
    case sint64     = 0x8E
    case uint64     = 0x8F
    case uint64z    = 0x90

    var size: Int {
        switch self {
        case .enumType, .sint8, .uint8, .uint8z, .byte, .string: return 1
        case .sint16, .uint16, .uint16z: return 2
        case .sint32, .uint32, .uint32z, .float32: return 4
        case .sint64, .uint64, .uint64z, .float64: return 8
        }
    }

    static func from(_ raw: UInt8) -> FITBaseType {
        return FITBaseType(rawValue: raw) ?? .byte
    }
}

// MARK: - Global Message Numbers

private enum FITGlobalMesgNum: UInt16 {
    case fileId     = 0
    case session    = 18
    case lap        = 19
    case record     = 20
    case activity   = 34
}

// MARK: - Internal Definition / Data Types

private struct FieldDef {
    let defNum: UInt8
    let size: UInt8
    let baseType: FITBaseType
}

private struct MesgDef {
    let localMesgType: UInt8
    let globalMesgNum: UInt16
    let isBigEndian: Bool
    let fields: [FieldDef]
}

private struct RawField {
    let defNum: UInt8
    let bytes: [UInt8]
    let baseType: FITBaseType
}

// MARK: - Data Reader

private final class DataReader {
    private let data: Data
    private(set) var offset: Int = 0

    init(_ data: Data) { self.data = data }

    var bytesRemaining: Int { data.count - offset }
    var isAtEnd: Bool { offset >= data.count }

    func peek() -> UInt8? {
        guard offset < data.count else { return nil }
        return data[offset]
    }

    func readByte() throws -> UInt8 {
        guard offset < data.count else { throw FITParseError.corruptData("Unexpected end of data") }
        let b = data[offset]; offset += 1; return b
    }

    func readBytes(_ count: Int) throws -> [UInt8] {
        guard offset + count <= data.count else { throw FITParseError.corruptData("Unexpected end of data") }
        let bytes = Array(data[offset..<offset + count])
        offset += count
        return bytes
    }

    func readUInt16LE() throws -> UInt16 {
        let b = try readBytes(2)
        return UInt16(b[0]) | (UInt16(b[1]) << 8)
    }

    func readUInt32LE() throws -> UInt32 {
        let b = try readBytes(4)
        return UInt32(b[0]) | (UInt32(b[1]) << 8) | (UInt32(b[2]) << 16) | (UInt32(b[3]) << 24)
    }

    func skip(_ count: Int) throws {
        guard offset + count <= data.count else { throw FITParseError.corruptData("Unexpected end of data") }
        offset += count
    }
}

// MARK: - FITParser

struct FITParser {
    let data: Data

    init(data: Data) { self.data = data }

    init(contentsOf url: URL) throws {
        self.data = try Data(contentsOf: url, options: .mappedIfSafe)
    }

    func parse() throws -> FITFile {
        let reader = DataReader(data)

        // Parse file header
        let headerSize = try reader.readByte()
        guard headerSize == 14 || headerSize == 12 else { throw FITParseError.invalidHeader }

        let protocolVersion = try reader.readByte()
        guard (protocolVersion >> 4) <= 2 else { throw FITParseError.unsupportedProtocol(protocolVersion) }

        _ = try reader.readUInt16LE() // profile version
        let dataSize = try reader.readUInt32LE()

        let magic = try reader.readBytes(4)
        guard magic == [0x2E, 0x46, 0x49, 0x54] else { throw FITParseError.invalidHeader } // ".FIT"

        if headerSize == 14 { try reader.skip(2) } // header CRC

        let dataEnd = reader.offset + Int(dataSize)
        guard dataEnd <= data.count else { throw FITParseError.corruptData("Data size exceeds file length") }

        // Parse records
        var mesgDefs: [UInt8: MesgDef] = [:]
        var fileId: FITFileId?
        var sessions: [FITSession] = []
        var laps: [FITLap] = []
        var records: [FITRecord] = []
        var lastTimestamp: UInt32 = 0

        while reader.offset < dataEnd {
            let headerByte = try reader.readByte()
            let isCompressedTimestamp = (headerByte & 0x80) != 0

            if isCompressedTimestamp {
                // Compressed timestamp header: bits 7=1, 6-5=localMesgType, 4-0=time offset
                let localType = (headerByte >> 5) & 0x03
                let timeOffset = UInt32(headerByte & 0x1F)
                let lower = lastTimestamp & 0x1F
                if timeOffset >= lower {
                    lastTimestamp = (lastTimestamp & ~0x1F) | timeOffset
                } else {
                    lastTimestamp = ((lastTimestamp & ~0x1F) &+ 32) | timeOffset
                }
                if let def = mesgDefs[localType] {
                    let rawFields = try readDataMessage(reader: reader, def: def)
                    if def.globalMesgNum == FITGlobalMesgNum.record.rawValue {
                        if let rec = decodeRecord(rawFields, timestamp: lastTimestamp) {
                            records.append(rec)
                        }
                    }
                }
            } else {
                let isDef = (headerByte & 0x40) != 0
                let localType = headerByte & 0x0F

                if isDef {
                    let devDataFlag = (headerByte & 0x20) != 0
                    let def = try readDefinitionMessage(reader: reader, localType: localType, hasDevFields: devDataFlag)
                    mesgDefs[localType] = def
                } else {
                    guard let def = mesgDefs[localType] else {
                        throw FITParseError.corruptData("Data message references undefined local type \(localType)")
                    }
                    let rawFields = try readDataMessage(reader: reader, def: def)

                    // Update rolling timestamp
                    if let tsField = rawFields.first(where: { $0.defNum == 253 }) {
                        lastTimestamp = readUInt32(tsField.bytes, bigEndian: false)
                    }

                    switch def.globalMesgNum {
                    case FITGlobalMesgNum.fileId.rawValue:
                        fileId = decodeFileId(rawFields)
                    case FITGlobalMesgNum.session.rawValue:
                        if let s = decodeSession(rawFields) { sessions.append(s) }
                    case FITGlobalMesgNum.lap.rawValue:
                        if let l = decodeLap(rawFields) { laps.append(l) }
                    case FITGlobalMesgNum.record.rawValue:
                        if let r = decodeRecord(rawFields, timestamp: lastTimestamp) { records.append(r) }
                    default:
                        break
                    }
                }
            }
        }

        return FITFile(fileId: fileId, sessions: sessions, laps: laps, records: records)
    }

    // MARK: - Message Readers

    private func readDefinitionMessage(reader: DataReader, localType: UInt8, hasDevFields: Bool) throws -> MesgDef {
        _ = try reader.readByte() // reserved
        let arch = try reader.readByte()
        let isBigEndian = arch == 1
        let globalNum = isBigEndian
            ? UInt16(try reader.readByte()) << 8 | UInt16(try reader.readByte())
            : try reader.readUInt16LE()
        let numFields = try reader.readByte()

        var fields: [FieldDef] = []
        for _ in 0..<numFields {
            let defNum = try reader.readByte()
            let size = try reader.readByte()
            let baseTypeRaw = try reader.readByte()
            let baseType = FITBaseType.from(baseTypeRaw)
            fields.append(FieldDef(defNum: defNum, size: size, baseType: baseType))
        }

        if hasDevFields {
            let numDevFields = try reader.readByte()
            try reader.skip(Int(numDevFields) * 3)
        }

        return MesgDef(localMesgType: localType, globalMesgNum: globalNum, isBigEndian: isBigEndian, fields: fields)
    }

    private func readDataMessage(reader: DataReader, def: MesgDef) throws -> [RawField] {
        var result: [RawField] = []
        for field in def.fields {
            let bytes = try reader.readBytes(Int(field.size))
            result.append(RawField(defNum: field.defNum, bytes: bytes, baseType: field.baseType))
        }
        return result
    }

    // MARK: - Decoders

    private func decodeFileId(_ fields: [RawField]) -> FITFileId {
        var manufacturer: UInt16?
        var product: UInt16?
        var serialNumber: UInt32?
        var timeCreated: Date?
        var type: UInt8?

        for f in fields {
            switch f.defNum {
            case 0: type = f.bytes.first
            case 1: manufacturer = readUInt16(f.bytes, bigEndian: false)
            case 2: product = readUInt16(f.bytes, bigEndian: false)
            case 3: serialNumber = readUInt32(f.bytes, bigEndian: false)
            case 4:
                let ts = readUInt32(f.bytes, bigEndian: false)
                if ts != 0xFFFFFFFF { timeCreated = fitDate(ts) }
            default: break
            }
        }
        return FITFileId(manufacturer: manufacturer, product: product, serialNumber: serialNumber, timeCreated: timeCreated, type: type)
    }

    private func decodeSession(_ fields: [RawField]) -> FITSession? {
        var timestamp: Date?
        var startTime: Date?
        var sport: UInt8?
        var subSport: UInt8?
        var totalElapsed: Double?
        var totalTimer: Double?
        var totalDistance: Double?
        var totalCalories: UInt16?
        var avgSpeed: Double?
        var maxSpeed: Double?
        var avgHR: UInt8?
        var maxHR: UInt8?
        var avgCadence: UInt8?
        var maxCadence: UInt8?
        var avgPower: UInt16?
        var maxPower: UInt16?
        var totalAscent: UInt16?
        var totalDescent: UInt16?
        var suuntoEPOC: Double?
        var suuntoRecovery: UInt16?
        var suuntoAerobicTE: Double?
        var suuntoAnaerobicTE: Double?

        for f in fields {
            switch f.defNum {
            case 253:
                let ts = readUInt32(f.bytes, bigEndian: false)
                if ts != 0xFFFFFFFF { timestamp = fitDate(ts) }
            case 2:
                let ts = readUInt32(f.bytes, bigEndian: false)
                if ts != 0xFFFFFFFF { startTime = fitDate(ts) }
            case 5: sport = f.bytes.first
            case 6: subSport = f.bytes.first
            case 7:
                let v = readUInt32(f.bytes, bigEndian: false)
                if v != 0xFFFFFFFF { totalElapsed = Double(v) / 1000.0 }
            case 8:
                let v = readUInt32(f.bytes, bigEndian: false)
                if v != 0xFFFFFFFF { totalTimer = Double(v) / 1000.0 }
            case 9:
                let v = readUInt32(f.bytes, bigEndian: false)
                if v != 0xFFFFFFFF { totalDistance = Double(v) / 100.0 }
            case 11:
                let v = readUInt16(f.bytes, bigEndian: false)
                if v != 0xFFFF { totalCalories = v }
            case 14:
                let v = readUInt16(f.bytes, bigEndian: false)
                if v != 0xFFFF { avgSpeed = Double(v) / 1000.0 }
            case 15:
                let v = readUInt16(f.bytes, bigEndian: false)
                if v != 0xFFFF { maxSpeed = Double(v) / 1000.0 }
            case 16: if f.bytes[0] != 0xFF { avgHR = f.bytes[0] }
            case 17: if f.bytes[0] != 0xFF { maxHR = f.bytes[0] }
            case 18: if f.bytes[0] != 0xFF { avgCadence = f.bytes[0] }
            case 19: if f.bytes[0] != 0xFF { maxCadence = f.bytes[0] }
            case 20:
                let v = readUInt16(f.bytes, bigEndian: false)
                if v != 0xFFFF { avgPower = v }
            case 21:
                let v = readUInt16(f.bytes, bigEndian: false)
                if v != 0xFFFF { maxPower = v }
            case 22:
                let v = readUInt16(f.bytes, bigEndian: false)
                if v != 0xFFFF { totalAscent = v }
            case 23:
                let v = readUInt16(f.bytes, bigEndian: false)
                if v != 0xFFFF { totalDescent = v }
            // Suunto-specific fields
            case 96:
                let v = readUInt16(f.bytes, bigEndian: false)
                if v != 0xFFFF { suuntoEPOC = Double(v) / 10.0 }
            case 87:
                let v = readUInt16(f.bytes, bigEndian: false)
                if v != 0xFFFF { suuntoRecovery = v }
            case 110:
                if !f.bytes.isEmpty && f.bytes[0] != 0xFF { suuntoAerobicTE = Double(f.bytes[0]) / 10.0 }
            case 111:
                if !f.bytes.isEmpty && f.bytes[0] != 0xFF { suuntoAnaerobicTE = Double(f.bytes[0]) / 10.0 }
            default: break
            }
        }

        return FITSession(
            startTime: startTime, timestamp: timestamp,
            sport: sport, subSport: subSport,
            totalElapsedSeconds: totalElapsed, totalTimerSeconds: totalTimer,
            totalDistanceMeters: totalDistance, totalCalories: totalCalories,
            avgSpeedMetersPerSec: avgSpeed, maxSpeedMetersPerSec: maxSpeed,
            avgHeartRateBPM: avgHR, maxHeartRateBPM: maxHR,
            avgCadenceRPM: avgCadence, maxCadenceRPM: maxCadence,
            avgPowerWatts: avgPower, maxPowerWatts: maxPower,
            totalAscent: totalAscent, totalDescent: totalDescent,
            suuntoEPOCml: suuntoEPOC, suuntoRecoveryTimeHours: suuntoRecovery,
            suuntoAerobicTE: suuntoAerobicTE, suuntoAnaerobicTE: suuntoAnaerobicTE
        )
    }

    private func decodeLap(_ fields: [RawField]) -> FITLap? {
        var timestamp: Date?
        var startTime: Date?
        var totalElapsed: Double?
        var totalTimer: Double?
        var totalDistance: Double?
        var totalCalories: UInt16?
        var avgSpeed: Double?
        var maxSpeed: Double?
        var avgHR: UInt8?
        var maxHR: UInt8?
        var totalAscent: UInt16?
        var totalDescent: UInt16?

        for f in fields {
            switch f.defNum {
            case 253:
                let ts = readUInt32(f.bytes, bigEndian: false)
                if ts != 0xFFFFFFFF { timestamp = fitDate(ts) }
            case 2:
                let ts = readUInt32(f.bytes, bigEndian: false)
                if ts != 0xFFFFFFFF { startTime = fitDate(ts) }
            case 7:
                let v = readUInt32(f.bytes, bigEndian: false)
                if v != 0xFFFFFFFF { totalElapsed = Double(v) / 1000.0 }
            case 8:
                let v = readUInt32(f.bytes, bigEndian: false)
                if v != 0xFFFFFFFF { totalTimer = Double(v) / 1000.0 }
            case 9:
                let v = readUInt32(f.bytes, bigEndian: false)
                if v != 0xFFFFFFFF { totalDistance = Double(v) / 100.0 }
            case 11:
                let v = readUInt16(f.bytes, bigEndian: false)
                if v != 0xFFFF { totalCalories = v }
            case 14:
                let v = readUInt16(f.bytes, bigEndian: false)
                if v != 0xFFFF { avgSpeed = Double(v) / 1000.0 }
            case 15:
                let v = readUInt16(f.bytes, bigEndian: false)
                if v != 0xFFFF { maxSpeed = Double(v) / 1000.0 }
            case 16: if f.bytes[0] != 0xFF { avgHR = f.bytes[0] }
            case 17: if f.bytes[0] != 0xFF { maxHR = f.bytes[0] }
            case 21:
                let v = readUInt16(f.bytes, bigEndian: false)
                if v != 0xFFFF { totalAscent = v }
            case 22:
                let v = readUInt16(f.bytes, bigEndian: false)
                if v != 0xFFFF { totalDescent = v }
            default: break
            }
        }

        return FITLap(
            startTime: startTime, timestamp: timestamp,
            totalElapsedSeconds: totalElapsed, totalTimerSeconds: totalTimer,
            totalDistanceMeters: totalDistance, totalCalories: totalCalories,
            avgSpeedMetersPerSec: avgSpeed, maxSpeedMetersPerSec: maxSpeed,
            avgHeartRateBPM: avgHR, maxHeartRateBPM: maxHR,
            totalAscent: totalAscent, totalDescent: totalDescent
        )
    }

    private func decodeRecord(_ fields: [RawField], timestamp: UInt32) -> FITRecord? {
        guard timestamp != 0xFFFFFFFF else { return nil }
        let date = fitDate(timestamp)

        var posLat: Double?
        var posLon: Double?
        var altitude: Double?
        var heartRate: UInt8?
        var cadence: UInt8?
        var speed: Double?
        var power: UInt16?
        var temperature: Int8?
        var distance: Double?
        var suuntoFusedSpeed: Double?

        for f in fields {
            switch f.defNum {
            case 0:
                if f.bytes.count == 4 {
                    let v = Int32(bitPattern: readUInt32(f.bytes, bigEndian: false))
                    if v != Int32(bitPattern: 0x7FFFFFFF) {
                        posLat = Double(v) * (180.0 / 2_147_483_648.0)
                    }
                }
            case 1:
                if f.bytes.count == 4 {
                    let v = Int32(bitPattern: readUInt32(f.bytes, bigEndian: false))
                    if v != Int32(bitPattern: 0x7FFFFFFF) {
                        posLon = Double(v) * (180.0 / 2_147_483_648.0)
                    }
                }
            case 2:
                if f.bytes.count == 2 {
                    let v = readUInt16(f.bytes, bigEndian: false)
                    if v != 0xFFFF { altitude = (Double(v) / 5.0) - 500.0 }
                }
            case 3: if f.bytes[0] != 0xFF { heartRate = f.bytes[0] }
            case 4: if f.bytes[0] != 0xFF { cadence = f.bytes[0] }
            case 5:
                if f.bytes.count == 4 {
                    let v = readUInt32(f.bytes, bigEndian: false)
                    if v != 0xFFFFFFFF { distance = Double(v) / 100.0 }
                }
            case 6:
                if f.bytes.count == 2 {
                    let v = readUInt16(f.bytes, bigEndian: false)
                    if v != 0xFFFF { speed = Double(v) / 1000.0 }
                }
            case 7:
                if f.bytes.count == 2 {
                    let v = readUInt16(f.bytes, bigEndian: false)
                    if v != 0xFFFF { power = v }
                }
            case 13: if !f.bytes.isEmpty { temperature = Int8(bitPattern: f.bytes[0]) }
            case 17:
                // enhanced_speed overrides field 6 when present
                if f.bytes.count == 4 {
                    let v = readUInt32(f.bytes, bigEndian: false)
                    if v != 0xFFFFFFFF { speed = Double(v) / 1000.0 }
                }
            case 30:
                // enhanced_altitude overrides field 2 when present
                if f.bytes.count == 4 {
                    let v = readUInt32(f.bytes, bigEndian: false)
                    if v != 0xFFFFFFFF { altitude = (Double(v) / 5.0) - 500.0 }
                }
            // Suunto-specific: GPS + accelerometer fused speed
            case 90:
                if f.bytes.count == 2 {
                    let v = readUInt16(f.bytes, bigEndian: false)
                    if v != 0xFFFF { suuntoFusedSpeed = Double(v) / 1000.0 }
                }
            default: break
            }
        }

        return FITRecord(
            timestamp: date,
            positionLatDegrees: posLat,
            positionLonDegrees: posLon,
            altitudeMeters: altitude,
            heartRateBPM: heartRate,
            cadenceRPM: cadence,
            speedMetersPerSec: speed,
            powerWatts: power,
            temperatureCelsius: temperature,
            distanceMeters: distance,
            suuntoFusedSpeedMps: suuntoFusedSpeed
        )
    }

    // MARK: - Helpers

    private func fitDate(_ timestamp: UInt32) -> Date {
        Date(timeIntervalSince1970: fitEpoch + Double(timestamp))
    }

    private func readUInt16(_ bytes: [UInt8], bigEndian: Bool) -> UInt16 {
        guard bytes.count >= 2 else { return 0xFFFF }
        return bigEndian
            ? UInt16(bytes[0]) << 8 | UInt16(bytes[1])
            : UInt16(bytes[0]) | UInt16(bytes[1]) << 8
    }

    private func readUInt32(_ bytes: [UInt8], bigEndian: Bool) -> UInt32 {
        guard bytes.count >= 4 else { return 0xFFFFFFFF }
        return bigEndian
            ? UInt32(bytes[0]) << 24 | UInt32(bytes[1]) << 16 | UInt32(bytes[2]) << 8 | UInt32(bytes[3])
            : UInt32(bytes[0]) | UInt32(bytes[1]) << 8 | UInt32(bytes[2]) << 16 | UInt32(bytes[3]) << 24
    }
}
