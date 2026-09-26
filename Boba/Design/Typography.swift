import SwiftUI

// MARK: - Typography System

/// Boba's typography system using SF Pro and SF Rounded.
/// SF Rounded is used for financial numbers for a friendlier feel.
enum BobaFont {
    // MARK: - Display (Hero numbers like "Safe to Spend")
    static func displayLarge() -> Font {
        .system(size: 48, weight: .bold, design: .rounded)
    }

    static func displayMedium() -> Font {
        .system(size: 36, weight: .bold, design: .rounded)
    }

    static func displaySmall() -> Font {
        .system(size: 28, weight: .semibold, design: .rounded)
    }

    // MARK: - Headings
    static func headlineLarge() -> Font {
        .system(size: 22, weight: .bold, design: .default)
    }

    static func headlineMedium() -> Font {
        .system(size: 18, weight: .semibold, design: .default)
    }

    static func headlineSmall() -> Font {
        .system(size: 16, weight: .semibold, design: .default)
    }

    // MARK: - Body
    static func bodyLarge() -> Font {
        .system(size: 17, weight: .regular, design: .default)
    }

    static func bodyMedium() -> Font {
        .system(size: 15, weight: .regular, design: .default)
    }

    static func bodySmall() -> Font {
        .system(size: 13, weight: .regular, design: .default)
    }

    // MARK: - Numbers (financial amounts)
    static func amountLarge() -> Font {
        .system(size: 42, weight: .bold, design: .rounded)
    }

    static func amountMedium() -> Font {
        .system(size: 24, weight: .semibold, design: .rounded)
    }

    static func amountSmall() -> Font {
        .system(size: 18, weight: .medium, design: .rounded)
    }

    static func amountTiny() -> Font {
        .system(size: 14, weight: .medium, design: .rounded)
    }

    // MARK: - Labels & Captions
    static func label() -> Font {
        .system(size: 12, weight: .medium, design: .default)
    }

    static func caption() -> Font {
        .system(size: 11, weight: .regular, design: .default)
    }

    static func overline() -> Font {
        .system(size: 10, weight: .bold, design: .default)
    }
}

// MARK: - Text Style Modifiers

extension View {
    func bobaDisplayLarge() -> some View {
        self.font(BobaFont.displayLarge())
            .foregroundStyle(BobaColors.textPrimary)
    }

    func bobaHeadline() -> some View {
        self.font(BobaFont.headlineLarge())
            .foregroundStyle(BobaColors.textPrimary)
    }

    func bobaBody() -> some View {
        self.font(BobaFont.bodyMedium())
            .foregroundStyle(BobaColors.textSecondary)
    }

    func bobaAmount() -> some View {
        self.font(BobaFont.amountLarge())
            .foregroundStyle(BobaColors.textPrimary)
    }

    func bobaLabel() -> some View {
        self.font(BobaFont.label())
            .foregroundStyle(BobaColors.textTertiary)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}
