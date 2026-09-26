import SwiftUI

// MARK: - Boba Color Palette

/// Central design token system for the Boba app.
/// All colors, spacing, radii, and shadows are defined here.
enum BobaColors {
    // Primary Palette
    static let shadowGrey = Color(hex: "221d23")
    static let deepWalnut = Color(hex: "4f3824")
    static let fieryTerracotta = Color(hex: "d1603d")
    static let metallicGold = Color(hex: "ddb967")
    static let limeCream = Color(hex: "d0e37f")

    // Semantic Colors
    static let background = shadowGrey
    static let surfacePrimary = Color(hex: "2e2831")
    static let surfaceSecondary = Color(hex: "3a3340")
    static let surfaceElevated = Color(hex: "453e4d")

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.45)
    static let textOnAccent = Color.white

    static let accent = fieryTerracotta
    static let accentSecondary = metallicGold
    static let positive = limeCream
    static let warning = metallicGold
    static let negative = fieryTerracotta
    static let income = limeCream
    static let expense = fieryTerracotta

    // Gradient Presets
    static let cardGradient = LinearGradient(
        colors: [surfacePrimary, surfaceSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [fieryTerracotta, metallicGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [metallicGold, Color(hex: "c9a54e")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let positiveGradient = LinearGradient(
        colors: [limeCream, Color(hex: "b8d45a")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Spacing

enum BobaSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
    static let huge: CGFloat = 56
}

// MARK: - Radii

enum BobaRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let pill: CGFloat = 999
}

// MARK: - Shadows

enum BobaShadow {
    static let cardShadow = Color.black.opacity(0.25)
    static let cardShadowRadius: CGFloat = 12
    static let elevatedShadow = Color.black.opacity(0.35)
    static let elevatedShadowRadius: CGFloat = 20
}

// MARK: - Animation

enum BobaAnimation {
    static let quick = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let standard = Animation.spring(response: 0.45, dampingFraction: 0.75)
    static let slow = Animation.spring(response: 0.6, dampingFraction: 0.7)
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
}

// MARK: - Color Extension (Hex Support)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
