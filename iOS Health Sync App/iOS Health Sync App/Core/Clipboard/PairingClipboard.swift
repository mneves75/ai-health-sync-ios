// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation
import UIKit
import UniformTypeIdentifiers

enum PairingClipboard {
    static let expirationInterval: TimeInterval = 5 * 60

    /// Builds a text-only pasteboard item with multiple text flavors.
    static func makeTextPasteboardItem(payload: String) -> [String: Any] {
        var item: [String: Any] = [
            UTType.plainText.identifier: payload,
            UTType.utf8PlainText.identifier: payload,
            UTType.text.identifier: payload
        ]
        if let jsonData = payload.data(using: .utf8) {
            item[UTType.json.identifier] = jsonData
        }
        return item
    }

    /// Builds a pasteboard item with multiple text flavors plus PNG for cross-device compatibility.
    static func makePasteboardItem(payload: String, pngData: Data) -> [String: Any] {
        var item = makeTextPasteboardItem(payload: payload)
        item[UTType.png.identifier] = pngData
        return item
    }

    /// Sets text and image atomically with an expiration to avoid stale QR payloads.
    static func setPayload(_ payload: String, pngData: Data, expiration: Date = Date().addingTimeInterval(expirationInterval)) {
        let item = makePasteboardItem(payload: payload, pngData: pngData)
        UIPasteboard.general.setItems([item], options: [.expirationDate: expiration])
    }

    /// Sets text-only payload with an expiration to avoid stale QR payloads.
    static func setTextPayload(_ payload: String, expiration: Date = Date().addingTimeInterval(expirationInterval)) {
        let item = makeTextPasteboardItem(payload: payload)
        UIPasteboard.general.setItems([item], options: [.expirationDate: expiration])
    }
}
