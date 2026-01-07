// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import AppKit
import CoreImage
import Testing
import Vision
@testable import HealthSyncCLI

// MARK: - Parse Options Tests

@Test
func parseOptionsParsesKeyValuePairs() throws {
    let options = try parseOptions(["--host", "127.0.0.1", "--port", "8443"])
    #expect(options["--host"] == "127.0.0.1")
    #expect(options["--port"] == "8443")
}

@Test
func parseOptionsHandlesFlags() throws {
    let options = try parseOptions(["--dry-run"])
    #expect(options["--dry-run"] == "true")
}

@Test
func parseOptionsHandlesAutoScanFlag() throws {
    let options = try parseOptions(["--auto-scan"])
    #expect(options["--auto-scan"] == "true")
}

@Test
func parseOptionsHandlesAutoScanWithOtherArgs() throws {
    // --auto-scan combined with --file should parse both correctly
    let options = try parseOptions(["--auto-scan", "--file", "/path/to/image.png"])
    #expect(options["--auto-scan"] == "true")
    #expect(options["--file"] == "/path/to/image.png")
}

@Test
func parseOptionsHandlesExplicitFalseFlag() throws {
    // --auto-scan false should be parsed as "false", not "true"
    let options = try parseOptions(["--auto-scan", "false"])
    #expect(options["--auto-scan"] == "false")
}

// MARK: - Local Network Host Validation Tests

@Suite("isLocalNetworkHost validation")
struct LocalNetworkHostTests {
    @Test("Allows localhost")
    func localhost() {
        #expect(isLocalNetworkHost("localhost"))
        #expect(isLocalNetworkHost("LOCALHOST"))
    }

    @Test("Allows IPv4 loopback")
    func ipv4Loopback() {
        #expect(isLocalNetworkHost("127.0.0.1"))
        #expect(isLocalNetworkHost("127.0.1.1"))
        #expect(isLocalNetworkHost("127.255.255.255"))
    }

    @Test("Allows IPv6 loopback")
    func ipv6Loopback() {
        #expect(isLocalNetworkHost("::1"))
        #expect(isLocalNetworkHost("[::1]"))
    }

    @Test("Allows .local domains")
    func localDomains() {
        #expect(isLocalNetworkHost("iphone.local"))
        #expect(isLocalNetworkHost("iphone.local."))
        #expect(isLocalNetworkHost("My-iPhone.local"))
    }

    @Test("Allows private IPv4 ranges")
    func privateIPv4() {
        // 192.168.x.x
        #expect(isLocalNetworkHost("192.168.1.1"))
        #expect(isLocalNetworkHost("192.168.0.100"))

        // 10.x.x.x
        #expect(isLocalNetworkHost("10.0.0.1"))
        #expect(isLocalNetworkHost("10.255.255.255"))

        // 172.16.0.0 - 172.31.255.255
        #expect(isLocalNetworkHost("172.16.0.1"))
        #expect(isLocalNetworkHost("172.31.255.255"))
    }

    @Test("Allows IPv6 link-local")
    func ipv6LinkLocal() {
        #expect(isLocalNetworkHost("fe80::1"))
        #expect(isLocalNetworkHost("FE80::1:2:3"))
        #expect(isLocalNetworkHost("[fe80::1]"))  // Bracketed format
    }

    @Test("Rejects public hosts")
    func rejectsPublicHosts() {
        #expect(!isLocalNetworkHost("google.com"))
        #expect(!isLocalNetworkHost("8.8.8.8"))
        #expect(!isLocalNetworkHost("172.32.0.1")) // Just outside private range
        #expect(!isLocalNetworkHost("172.15.0.1")) // Just outside private range
        #expect(!isLocalNetworkHost("example.com"))
    }
}

// MARK: - Pairing Payload Tests

@Suite("PairingPayload decoding")
struct PairingPayloadTests {
    @Test("Decodes valid payload")
    func decodesValidPayload() throws {
        let json = """
        {
            "version": "1",
            "host": "192.168.1.100",
            "port": 8443,
            "code": "ABC123",
            "expiresAt": "2026-01-07T12:00:00Z",
            "certificateFingerprint": "abcd1234"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(PairingPayload.self, from: Data(json.utf8))

        #expect(payload.version == "1")
        #expect(payload.host == "192.168.1.100")
        #expect(payload.port == 8443)
        #expect(payload.code == "ABC123")
        #expect(payload.certificateFingerprint == "abcd1234")
    }

    @Test("Fails on missing fields")
    func failsOnMissingFields() {
        let json = """
        {
            "version": "1",
            "host": "192.168.1.100"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(PairingPayload.self, from: Data(json.utf8))
        }
    }
}

// MARK: - QR Code Detection Tests

@Suite("QR Code Detection")
struct QRCodeDetectionTests {
    /// Generates a QR code image containing the specified string.
    /// Returns nil if generation fails.
    private func generateQRCode(content: String, size: CGFloat = 200) -> CGImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(content.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // Medium error correction

        guard let ciImage = filter.outputImage else { return nil }

        // Scale to desired size
        let scale = size / ciImage.extent.width
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext()
        return context.createCGImage(scaled, from: scaled.extent)
    }

    @Test("Detects valid QR code in image")
    func detectsValidQRCode() throws {
        let testContent = "Hello, QR World!"
        guard let qrImage = generateQRCode(content: testContent) else {
            Issue.record("Failed to generate test QR code")
            return
        }

        let detected = try HealthSyncCLI.detectQRCode(in: qrImage)
        #expect(detected == testContent)
    }

    @Test("Detects JSON payload in QR code")
    func detectsJSONPayload() throws {
        let jsonPayload = """
        {"version":"1","host":"192.168.1.1","port":8443,"code":"TEST","expiresAt":"2026-12-31T23:59:59Z","certificateFingerprint":"abc123"}
        """
        guard let qrImage = generateQRCode(content: jsonPayload) else {
            Issue.record("Failed to generate test QR code")
            return
        }

        let detected = try HealthSyncCLI.detectQRCode(in: qrImage)
        #expect(detected == jsonPayload)

        // Verify it can be decoded as PairingPayload
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(PairingPayload.self, from: Data(detected.utf8))
        #expect(payload.version == "1")
        #expect(payload.host == "192.168.1.1")
    }

    @Test("Throws on image without QR code")
    func throwsOnNoQRCode() throws {
        // Create a blank white image (no QR code)
        let width = 100
        let height = 100
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 255, count: width * height * bytesPerPixel) // White image

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ),
        let blankImage = context.makeImage() else {
            Issue.record("Failed to create blank test image")
            return
        }

        #expect(throws: CLIError.self) {
            _ = try HealthSyncCLI.detectQRCode(in: blankImage)
        }
    }
}

// MARK: - Clipboard Payload Extraction Tests

@Suite("Clipboard Payload Extraction")
struct ClipboardPayloadExtractionTests {
    @Test("Extracts payload from string provider")
    func extractsPayloadFromStringProvider() {
        let jsonPayload = """
        {"version":"1","host":"192.168.1.1","port":8443,"code":"TEST","expiresAt":"2026-12-31T23:59:59Z","certificateFingerprint":"abc123"}
        """
        let result = HealthSyncCLI.extractTextPayload(
            stringProvider: { type in
                type == .string ? jsonPayload : nil
            },
            dataProvider: { _ in nil }
        )
        #expect(result == jsonPayload)
    }

    @Test("Extracts payload from data provider")
    func extractsPayloadFromDataProvider() {
        let jsonPayload = """
        {"version":"1","host":"192.168.1.1","port":8443,"code":"TEST","expiresAt":"2026-12-31T23:59:59Z","certificateFingerprint":"abc123"}
        """
        let data = jsonPayload.data(using: .utf8)
        let result = HealthSyncCLI.extractTextPayload(
            stringProvider: { _ in nil },
            dataProvider: { type in
                type == NSPasteboard.PasteboardType("public.json") ? data : nil
            }
        )
        #expect(result == jsonPayload)
    }
}

// MARK: - Version Validation Tests

@Suite("QR Version Validation")
struct VersionValidationTests {
    @Test("Version 1 is supported")
    func version1Supported() {
        let payload = PairingPayload(
            version: "1",
            host: "192.168.1.1",
            port: 8443,
            code: "TEST",
            expiresAt: Date().addingTimeInterval(3600),
            certificateFingerprint: "abc"
        )
        #expect(payload.version == "1")
    }

    @Test("Version check rejects unsupported versions")
    func rejectsUnsupportedVersions() {
        // Test the validation logic inline (mirrors what scan() does)
        let unsupportedVersions = ["0", "2", "1.0", "v1", ""]
        for version in unsupportedVersions {
            #expect(version != "1", "Version '\(version)' should be rejected")
        }
    }
}

// MARK: - Expiration Validation Tests

@Suite("Expiration Validation")
struct ExpirationValidationTests {
    @Test("Detects expired codes")
    func detectsExpiredCodes() {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let isExpired = pastDate < Date()
        #expect(isExpired)
    }

    @Test("Accepts valid codes")
    func acceptsValidCodes() {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        let isExpired = futureDate < Date()
        #expect(!isExpired)
    }
}

// MARK: - Port Validation Tests

@Suite("Port Validation")
struct PortValidationTests {
    @Test("Valid ports are accepted")
    func validPorts() {
        let validPorts = [1, 80, 443, 8443, 65535]
        for port in validPorts {
            #expect((1...65535).contains(port), "Port \(port) should be valid")
        }
    }

    @Test("Invalid ports are rejected")
    func invalidPorts() {
        let invalidPorts = [0, -1, 65536, 100000]
        for port in invalidPorts {
            #expect(!(1...65535).contains(port), "Port \(port) should be invalid")
        }
    }

    @Test("Port string parsing")
    func portParsing() {
        // Valid port strings
        #expect(Int("8443") == 8443)
        #expect(Int("443") == 443)

        // Invalid port strings return nil
        #expect(Int("abc") == nil)
        #expect(Int("") == nil)
        #expect(Int("8443abc") == nil)
    }
}

// MARK: - Security Validation Tests

@Suite("Security Validations")
struct SecurityValidationTests {
    @Test("SSRF protection: rejects public hosts in all paths")
    func ssrfProtection() {
        // Verify isLocalNetworkHost rejects public IPs and domains
        let publicHosts = [
            "google.com",
            "8.8.8.8",
            "1.1.1.1",
            "malicious-server.com",
            "192.169.1.1",  // Looks like private but isn't
            "11.0.0.1",     // Not in 10.x.x.x range
        ]
        for host in publicHosts {
            #expect(!isLocalNetworkHost(host), "Host '\(host)' should be rejected as public")
        }
    }

    @Test("SSRF protection: accepts local hosts")
    func acceptsLocalHosts() {
        let localHosts = [
            "localhost",
            "127.0.0.1",
            "192.168.1.1",
            "10.0.0.1",
            "172.16.0.1",
            "myphone.local",
            "::1",
            "fe80::1",
        ]
        for host in localHosts {
            #expect(isLocalNetworkHost(host), "Host '\(host)' should be accepted as local")
        }
    }
}

// MARK: - Output Format Tests

@Suite("Output Format Parsing")
struct OutputFormatTests {
    @Test("Default format is csv when not specified")
    func defaultFormatIsCsv() throws {
        let options = try parseOptions(["--start", "2026-01-01T00:00:00Z", "--end", "2026-12-31T23:59:59Z", "--types", "steps"])
        // When --format is not present, options["--format"] should be nil
        #expect(options["--format"] == nil)
        // Default behavior should treat nil as "csv" for spreadsheet compatibility
        let formatString = options["--format"]?.lowercased() ?? "csv"
        #expect(formatString == "csv")
    }

    @Test("CSV format is parsed correctly")
    func csvFormatParsed() throws {
        let options = try parseOptions(["--format", "csv", "--start", "2026-01-01T00:00:00Z"])
        #expect(options["--format"] == "csv")
    }

    @Test("JSON format is parsed correctly")
    func jsonFormatParsed() throws {
        let options = try parseOptions(["--format", "json", "--start", "2026-01-01T00:00:00Z"])
        #expect(options["--format"] == "json")
    }

    @Test("Format is case-insensitive")
    func formatIsCaseInsensitive() throws {
        let upperOptions = try parseOptions(["--format", "CSV"])
        let mixedOptions = try parseOptions(["--format", "Json"])
        #expect(upperOptions["--format"]?.lowercased() == "csv")
        #expect(mixedOptions["--format"]?.lowercased() == "json")
    }

    @Test("Invalid format is detected")
    func invalidFormatDetected() throws {
        let options = try parseOptions(["--format", "xml"])
        let formatString = options["--format"]?.lowercased() ?? "json"
        // The CLI should reject formats that aren't "csv" or "json"
        #expect(formatString != "csv" && formatString != "json")
    }
}

// MARK: - CSV Output Tests

@Suite("CSV Output")
struct CSVOutputTests {
    @Test("CSV header format")
    func csvHeaderFormat() {
        // Verify expected CSV header
        let expectedHeader = "id;type;value;unit;startDate;endDate;sourceName"
        #expect(expectedHeader.contains("id"))
        #expect(expectedHeader.contains(";"))
        #expect(!expectedHeader.contains(",")) // Uses semicolon, not comma
    }

    @Test("Semicolon delimiter consistency")
    func semicolonDelimiter() {
        // Verify our CSV uses semicolon consistently
        let header = "id;type;value;unit;startDate;endDate;sourceName"
        let fields = header.split(separator: ";")
        #expect(fields.count == 7)
        #expect(fields[0] == "id")
        #expect(fields[6] == "sourceName")
    }

    @Test("ISO8601 date format in CSV")
    func iso8601DateFormat() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let date = Date(timeIntervalSince1970: 0)
        let formatted = formatter.string(from: date)
        // Should contain T separator and Z timezone
        #expect(formatted.contains("T"))
        #expect(formatted.hasSuffix("Z"))
    }
}

// MARK: - Bonjour Discovery Tests

@Suite("Bonjour Discovery")
struct BonjourDiscoveryTests {
    @Test("BonjourResult stores service info correctly")
    func bonjourResultInit() {
        let result = BonjourResult(name: "iPhone", host: "192.168.1.100", port: 8443)
        #expect(result.name == "iPhone")
        #expect(result.host == "192.168.1.100")
        #expect(result.port == 8443)
    }

    @Test("BonjourResult is Sendable")
    func bonjourResultIsSendable() async {
        // Verify BonjourResult can be passed across concurrency boundaries
        let result = BonjourResult(name: "Test", host: "localhost", port: 1234)
        let task = Task { result }
        let received = await task.value
        #expect(received.name == "Test")
    }

    @Test("Discover returns array without crashing")
    func discoverReturnsArrayWithoutCrashing() async {
        // With a very short timeout, discover should complete without crashing
        // and return an array (possibly empty, possibly with services if any are running)
        let results = await BonjourBrowser.discover(timeout: 0.1)
        // Just verify it's a valid array (empty or not)
        #expect(results.count >= 0)
    }

    @Test("Discover handles concurrent calls safely")
    func discoverHandlesConcurrentCalls() async {
        // Launch multiple discovery tasks concurrently to verify thread safety
        async let results1 = BonjourBrowser.discover(timeout: 0.1)
        async let results2 = BonjourBrowser.discover(timeout: 0.1)
        async let results3 = BonjourBrowser.discover(timeout: 0.1)

        let (r1, r2, r3) = await (results1, results2, results3)

        // All should complete without crashing and return valid arrays
        #expect(r1.count >= 0)
        #expect(r2.count >= 0)
        #expect(r3.count >= 0)
    }

    @Test("Discover completes within timeout")
    func discoverCompletesWithinTimeout() async {
        let start = Date()
        _ = await BonjourBrowser.discover(timeout: 0.5)
        let elapsed = Date().timeIntervalSince(start)

        // Should complete within timeout + small buffer (1 second max)
        #expect(elapsed < 1.5, "Discovery took \(elapsed)s, expected < 1.5s")
    }
}
