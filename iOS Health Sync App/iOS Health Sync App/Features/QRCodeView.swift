// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

/// A view that displays a QR code for the given text payload.
///
/// Uses `QRCodeRenderer` to generate a QR code image synchronously.
/// QR code generation is fast (<10ms) so direct computation in the view body
/// guarantees the displayed QR always matches the current payload.
///
/// **Important**: No caching is used to avoid stale QR code bugs where the
/// displayed QR doesn't match the current pairing code after refresh.
struct QRCodeView: View {
    let text: String
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Larger on iPad / wide layouts, compact on iPhone. The QR scales to fit the
    /// available width up to a sensible cap so it stays scannable from across a desk
    /// on iPad without ballooning on iPhone.
    private var maxSide: CGFloat {
        sizeClass == .regular ? 360 : 240
    }

    var body: some View {
        // Compute QR image directly from current text - no caching.
        // This guarantees the displayed QR always matches the payload.
        // QR generation is fast (~5ms) so this is acceptable.
        let image = QRCodeRenderer.render(payload: text)

        Group {
            if let image {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: maxSide, maxHeight: maxSide)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Pairing QR code")
                    .accessibilityHint("Scan with the HealthSync CLI on your Mac to pair.")
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "qrcode")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Unable to generate QR code")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .frame(width: maxSide, height: maxSide)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
