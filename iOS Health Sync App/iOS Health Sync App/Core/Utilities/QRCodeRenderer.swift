// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import os

/// Thread-safe QR code renderer using Core Image.
///
/// Uses the modern `CIFilter.qrCodeGenerator()` API with typed properties
/// for reliable QR code generation.
///
/// **Important**: CIQRCodeGenerator outputs black modules on a TRANSPARENT background.
/// This renderer draws the QR code onto a white background using UIGraphicsImageRenderer
/// for guaranteed visibility in both light and dark modes.
enum QRCodeRenderer {
    /// Shared CIContext for rendering. Thread-safe per Apple documentation.
    private static let context = CIContext()

    /// Generates a QR code image from a payload string.
    ///
    /// - Parameters:
    ///   - payload: The string to encode in the QR code. Must not be empty.
    ///   - scale: Scale factor for the output image. Default is 8 (produces ~200px image).
    /// - Returns: A UIImage containing the QR code with white background, or nil if generation fails.
    ///
    /// - Note: This method is thread-safe and can be called from any thread.
    static func render(payload: String, scale: CGFloat = 8) -> UIImage? {
        guard !payload.isEmpty else {
            AppLoggers.app.error("QR code render skipped: empty payload")
            return nil
        }

        // Convert string to Data (required by CIQRCodeGenerator)
        let data = Data(payload.utf8)

        // Generate QR code using Core Image
        let qrFilter = CIFilter.qrCodeGenerator()
        qrFilter.message = data
        qrFilter.correctionLevel = "M"  // Medium error correction (~15% recovery)

        guard let ciImage = qrFilter.outputImage else {
            AppLoggers.app.error("QR code render failed: CIFilter outputImage is nil for payload size \(data.count) bytes")
            return nil
        }

        // Scale up the QR code (native size is very small, typically 21x21 to 177x177 modules)
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Render CIImage to CGImage
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else {
            AppLoggers.app.error("QR code render failed: CGImage creation returned nil")
            return nil
        }

        // CRITICAL: CIQRCodeGenerator outputs black modules on TRANSPARENT background.
        // Use UIGraphicsImageRenderer to draw on an explicit white background.
        // This guarantees visibility in both light and dark modes.
        let size = CGSize(width: scaled.extent.width, height: scaled.extent.height)
        let renderer = UIGraphicsImageRenderer(size: size)

        let finalImage = renderer.image { ctx in
            // Fill entire canvas with white
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Draw the QR code on top (black modules will appear on white background)
            let qrUIImage = UIImage(cgImage: cgImage)
            qrUIImage.draw(in: CGRect(origin: .zero, size: size))
        }

        return finalImage
    }
}
