// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Testing
import UniformTypeIdentifiers
@testable import iOS_Health_Sync_App

@Test
func pairingClipboardBuildsPasteboardItem() {
    let payload = """
    {"version":"1","host":"192.168.1.1","port":8443,"code":"TEST","expiresAt":"2026-12-31T23:59:59Z","certificateFingerprint":"abc123"}
    """
    let pngData = Data([0x89, 0x50, 0x4E, 0x47])
    let item = PairingClipboard.makePasteboardItem(payload: payload, pngData: pngData)

    #expect(item[UTType.plainText.identifier] as? String == payload)
    #expect(item[UTType.utf8PlainText.identifier] as? String == payload)
    #expect(item[UTType.text.identifier] as? String == payload)
    #expect(item[UTType.png.identifier] as? Data == pngData)
    #expect(item[UTType.json.identifier] as? Data == payload.data(using: .utf8))
}

@Test
func pairingClipboardBuildsTextOnlyItem() {
    let payload = """
    {"version":"1","host":"192.168.1.1","port":8443,"code":"TEST","expiresAt":"2026-12-31T23:59:59Z","certificateFingerprint":"abc123"}
    """
    let item = PairingClipboard.makeTextPasteboardItem(payload: payload)

    #expect(item[UTType.plainText.identifier] as? String == payload)
    #expect(item[UTType.utf8PlainText.identifier] as? String == payload)
    #expect(item[UTType.text.identifier] as? String == payload)
    #expect(item[UTType.json.identifier] as? Data == payload.data(using: .utf8))
    #expect(item[UTType.png.identifier] == nil)
}
