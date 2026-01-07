// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

enum LiquidGlassProminence {
    case standard
    case prominent
}

struct LiquidGlassContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}

extension View {
    @ViewBuilder
    func liquidGlassButtonStyle(_ prominence: LiquidGlassProminence) -> some View {
        if #available(iOS 26, *) {
            switch prominence {
            case .standard:
                buttonStyle(.glass)
            case .prominent:
                buttonStyle(.glassProminent)
            }
        } else {
            switch prominence {
            case .standard:
                buttonStyle(.bordered)
            case .prominent:
                buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    func liquidGlassSurface<S: Shape>(
        tint: Color? = nil,
        interactive: Bool = false,
        in shape: S
    ) -> some View {
        if #available(iOS 26, *) {
            if let tint {
                if interactive {
                    glassEffect(.regular.tint(tint).interactive(), in: shape)
                } else {
                    glassEffect(.regular.tint(tint), in: shape)
                }
            } else {
                if interactive {
                    glassEffect(.regular.interactive(), in: shape)
                } else {
                    glassEffect(.regular, in: shape)
                }
            }
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }

    @ViewBuilder
    func liquidGlassEffectID(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26, *) {
            glassEffectID(id, in: namespace)
        } else {
            self
        }
    }
}
