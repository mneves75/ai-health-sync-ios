// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Testing
import UIKit
@testable import iOS_Health_Sync_App

// MARK: - Basic Rendering Tests

@Test
func qrCodeRendererReturnsImage() {
    let image = QRCodeRenderer.render(payload: "HealthSync-Test")
    #expect(image != nil)
}

@Test
func qrCodeRendererReturnsNilForEmptyPayload() {
    let image = QRCodeRenderer.render(payload: "")
    #expect(image == nil, "Empty payload should return nil")
}

@Test
func qrCodeRendererProducesNonZeroSizeImage() {
    let image = QRCodeRenderer.render(payload: "Test")
    #expect(image != nil)
    #expect(image!.size.width > 0)
    #expect(image!.size.height > 0)
}

// MARK: - White Background Tests (Critical for dark mode visibility)

@Test
func qrCodeRendererHasWhiteBackground() {
    // Generate a simple QR code
    let image = QRCodeRenderer.render(payload: "Test")
    #expect(image != nil, "Image should be generated")

    guard let cgImage = image?.cgImage else {
        Issue.record("Failed to get CGImage")
        return
    }

    // Sample corner pixel - should be white (part of quiet zone)
    // QR codes have a "quiet zone" of white space around the modules
    let pixelColor = getPixelColor(from: cgImage, at: CGPoint(x: 0, y: 0))

    // White pixel should have R, G, B all close to 1.0
    #expect(pixelColor.red > 0.95, "Corner pixel red channel should be white (got \(pixelColor.red))")
    #expect(pixelColor.green > 0.95, "Corner pixel green channel should be white (got \(pixelColor.green))")
    #expect(pixelColor.blue > 0.95, "Corner pixel blue channel should be white (got \(pixelColor.blue))")
}

@Test
func qrCodeRendererHasOpaqueBackground() {
    // CRITICAL: CIQRCodeGenerator outputs TRANSPARENT background
    // Our fix must ensure the background is OPAQUE white
    let image = QRCodeRenderer.render(payload: "Test")
    #expect(image != nil, "Image should be generated")

    guard let cgImage = image?.cgImage else {
        Issue.record("Failed to get CGImage")
        return
    }

    // Sample corner pixel - should be fully opaque
    let pixelColor = getPixelColor(from: cgImage, at: CGPoint(x: 0, y: 0))
    #expect(pixelColor.alpha > 0.95, "Corner pixel should be opaque (got alpha \(pixelColor.alpha))")
}

// MARK: - Scale Factor Tests

@Test
func qrCodeRendererRespectsScaleFactor() {
    let scale: CGFloat = 4
    let image = QRCodeRenderer.render(payload: "Test", scale: scale)
    #expect(image != nil)

    // QR code for "Test" is version 1 (21x21 modules)
    // With scale 4, expected size is 21 * 4 = 84
    // Allow some tolerance for different QR versions
    let minExpectedSize = 21 * scale  // Version 1 QR
    #expect(image!.size.width >= minExpectedSize, "Width should be at least \(minExpectedSize)")
    #expect(image!.size.height >= minExpectedSize, "Height should be at least \(minExpectedSize)")
}

@Test
func qrCodeRendererProducesSquareImage() {
    let image = QRCodeRenderer.render(payload: "HealthSync-Pairing-Code")
    #expect(image != nil)
    #expect(image!.size.width == image!.size.height, "QR code should be square")
}

// MARK: - Consistency Tests

@Test
func qrCodeRendererProducesConsistentResults() {
    // Same payload should produce same image dimensions
    let payload = "Consistent-Test-Payload"
    let image1 = QRCodeRenderer.render(payload: payload)
    let image2 = QRCodeRenderer.render(payload: payload)

    #expect(image1 != nil && image2 != nil)
    #expect(image1!.size == image2!.size, "Same payload should produce same size images")
}

// MARK: - Helper Functions

/// Extracts pixel color at a specific point from a CGImage
private func getPixelColor(from cgImage: CGImage, at point: CGPoint) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
    let width = cgImage.width
    let height = cgImage.height

    // Clamp point to valid range
    let x = max(0, min(Int(point.x), width - 1))
    let y = max(0, min(Int(point.y), height - 1))

    // Create bitmap context to read pixel data
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    var pixelData = [UInt8](repeating: 0, count: bytesPerRow * height)

    guard let context = CGContext(
        data: &pixelData,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return (0, 0, 0, 0)
    }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    let pixelIndex = (y * bytesPerRow) + (x * bytesPerPixel)
    let r = CGFloat(pixelData[pixelIndex]) / 255.0
    let g = CGFloat(pixelData[pixelIndex + 1]) / 255.0
    let b = CGFloat(pixelData[pixelIndex + 2]) / 255.0
    let a = CGFloat(pixelData[pixelIndex + 3]) / 255.0

    return (r, g, b, a)
}
