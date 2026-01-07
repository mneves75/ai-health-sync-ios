// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Testing
import UIKit
@testable import iOS_Health_Sync_App

@Test @MainActor
func qrCodeViewModelPrefersLatestPayload() async {
    let renderer: QRCodeViewModel.Renderer = { payload in
        if payload == "slow" {
            try? await Task.sleep(for: .milliseconds(80))
        }
        return UIImage()
    }
    let model = QRCodeViewModel(renderer: renderer)

    model.render(payload: "slow")
    model.render(payload: "fast")

    try? await Task.sleep(for: .milliseconds(120))

    #expect(model.lastRenderedPayload == "fast")
    #expect(model.image != nil)
}

@Test @MainActor
func qrCodeViewModelCancelPreventsPublish() async {
    let renderer: QRCodeViewModel.Renderer = { payload in
        try? await Task.sleep(for: .milliseconds(80))
        return UIImage()
    }
    let model = QRCodeViewModel(renderer: renderer)

    model.render(payload: "cancel")
    model.cancel()

    try? await Task.sleep(for: .milliseconds(120))

    #expect(model.lastRenderedPayload == nil)
    #expect(model.image == nil)
}
