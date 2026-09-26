import SwiftUI

/// Large formatted currency display used for hero numbers.
struct AmountDisplay: View {
    let amount: String
    let label: String
    var size: AmountSize = .large
    var color: Color = BobaColors.textPrimary
    var labelColor: Color = BobaColors.textTertiary

    enum AmountSize {
        case large, medium, small

        var font: Font {
            switch self {
            case .large: return BobaFont.amountLarge()
            case .medium: return BobaFont.amountMedium()
            case .small: return BobaFont.amountSmall()
            }
        }
    }

    var body: some View {
        VStack(spacing: BobaSpacing.xxs) {
            Text(label)
                .font(BobaFont.label())
                .foregroundStyle(labelColor)
                .textCase(.uppercase)
                .tracking(0.8)

            Text(amount)
                .font(size.font)
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
    }
}

/// Quick action button for the dashboard (Add Expense, Add Income).
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            BobaHaptics.medium()
            action()
        }) {
            VStack(spacing: BobaSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())

                Text(label)
                    .font(BobaFont.caption())
                    .foregroundStyle(BobaColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Glassmorphic card container used throughout the app.
struct BobaCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(BobaSpacing.md)
            .background(BobaColors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.lg))
            .shadow(color: BobaShadow.cardShadow, radius: BobaShadow.cardShadowRadius, y: 4)
    }
}

/// Styled section header for lists.
struct BobaSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"

    var body: some View {
        HStack {
            Text(title)
                .font(BobaFont.headlineMedium())
                .foregroundStyle(BobaColors.textPrimary)

            Spacer()

            if let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(BobaFont.bodySmall())
                        .foregroundStyle(BobaColors.fieryTerracotta)
                }
            }
        }
    }
}

/// An income/expense summary pill.
struct IncomeExpensePill: View {
    let label: String
    let amount: String
    let type: TransactionType

    private var color: Color {
        type == .income ? BobaColors.limeCream : BobaColors.fieryTerracotta
    }

    private var icon: String {
        type == .income ? "arrow.down.right" : "arrow.up.right"
    }

    var body: some View {
        HStack(spacing: BobaSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(BobaFont.caption())
                    .foregroundStyle(BobaColors.textTertiary)

                Text(amount)
                    .font(BobaFont.amountTiny())
                    .foregroundStyle(BobaColors.textPrimary)
            }
        }
        .padding(.horizontal, BobaSpacing.sm)
        .padding(.vertical, BobaSpacing.xs)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
    }
}

#Preview("Components") {
    VStack(spacing: 20) {
        AmountDisplay(amount: "€1,234.56", label: "Safe to Spend")

        HStack(spacing: 16) {
            QuickActionButton(icon: "arrow.up.circle.fill", label: "Expense", color: BobaColors.fieryTerracotta) {}
            QuickActionButton(icon: "arrow.down.circle.fill", label: "Income", color: BobaColors.limeCream) {}
        }

        HStack {
            IncomeExpensePill(label: "Income", amount: "€3,200", type: .income)
            IncomeExpensePill(label: "Expenses", amount: "€1,965", type: .expense)
        }
    }
    .padding()
    .background(BobaColors.background)
}
