import SwiftUI

/// Style variant for Liquid Glass surfaces.
public enum LiquidGlassVariant {
    /// Regular glass with luminosity adjustment and background blur (ideal for controls, tab bars, modals).
    case regular
    /// Clear glass for high translucency over rich backgrounds.
    case clear
}

/// View modifier applying Apple's Liquid Glass material on modern iOS with backwards compatibility.
public struct LiquidGlassModifier<S: Shape>: ViewModifier {
    var variant: LiquidGlassVariant
    var shape: S
    var interactive: Bool

    public func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            switch variant {
            case .regular:
                content.glassEffect(.regular, in: shape)
            case .clear:
                content.glassEffect(.clear, in: shape)
            }
        } else {
            content
                .background {
                    ZStack {
                        shape
                            .fill(BobaColors.surfaceElevated.opacity(0.65))
                            .background(.ultraThinMaterial, in: shape)

                        // Ambient specular gradient highlight
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.12),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                }
                .overlay {
                    shape
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.28),
                                    Color.white.opacity(0.06),
                                    Color.black.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
    }
}

public extension View {
    /// Applies Apple's Liquid Glass material anchored to the view's shape.
    func liquidGlass<S: Shape>(_ variant: LiquidGlassVariant = .regular, in shape: S) -> some View {
        self.modifier(LiquidGlassModifier(variant: variant, shape: shape, interactive: true))
    }

    /// Convenience for capsule-shaped Liquid Glass controls (e.g. navigation bars, floating buttons).
    func liquidGlassCapsule(_ variant: LiquidGlassVariant = .regular) -> some View {
        self.modifier(LiquidGlassModifier(variant: variant, shape: Capsule(), interactive: true))
    }
}
