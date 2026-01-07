# Changelog

All notable changes to HealthSyncCLI will be documented in this file.

## [Unreleased]

### Added
- `scan --debug-pasteboard` flag to inspect available pasteboard types and sizes
- Clipboard payload extraction helper for improved test coverage
- `discover` command for automatic device discovery via Bonjour/mDNS
  - Uses modern Network framework (NWBrowser) for reliable service discovery
  - Resolves service endpoints to IP:port automatically
  - Shows helpful troubleshooting tips when no devices found
  - Swift 6 strict concurrency compliant with thread-safe state management
  - `--auto-scan` flag to automatically scan QR from clipboard after discovery
- `scan` command for QR code scanning from clipboard or file
  - Uses macOS Vision framework for reliable QR detection
  - Automatic pairing after successful scan
  - Support for `--file <path>` option to scan from image file
- Comprehensive test suite with 28 tests covering:
  - QR code detection with CoreImage-generated test images
  - Local network host validation (SSRF protection)
  - Pairing payload decoding
  - Port validation
  - Version and expiration validation

### Security
- **CRITICAL**: Added SSRF protection to `pair --host` command
  - Manual host input now validated against local network ranges
  - Previously only `--qr` path had this validation
- Added version validation to `pair --qr` command
- Added expiration check to `pair --qr` command
- Added port range validation (1-65535) with clear error messages
- Complete local network validation covering:
  - localhost
  - IPv4 loopback (127.x.x.x)
  - IPv6 loopback (::1)
  - Private IPv4 ranges (10.x.x.x, 172.16-31.x.x, 192.168.x.x)
  - IPv6 link-local (fe80::)
  - .local domains (mDNS/Bonjour)

### Fixed
- Clipboard parsing now checks multiple text flavors (plain text, UTF-8, JSON) for Universal Clipboard compatibility
- **CRITICAL**: Fixed `discover` command not finding devices
  - Root cause: Old `NetServiceBrowser` requires RunLoop for delegate callbacks
  - Async/await context didn't run a RunLoop, so callbacks never fired
  - Replaced with modern `NWBrowser` from Network framework
  - Added service resolution using `NWConnection` to get actual IP:port
- Replaced fragile continuation pattern in `detectQRCode` with synchronous Vision API usage
- Fixed hardcoded 2024 dates in help text - now dynamically generated
- Added MainActor isolation for AppKit clipboard operations (Swift 6 concurrency compliance)

### Changed
- Improved error messages for better user experience
- Help text now shows Quick Start instructions for scan workflow
