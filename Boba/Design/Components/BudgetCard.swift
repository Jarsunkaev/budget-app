import SwiftUI

/// A budget category card showing progress toward the limit.
/// Displays envelope-style fill with animated progress bar.
struct BudgetCard: View {
    let categoryName: String
    let categoryIcon: String
    let categoryColorHex: String
    let spent: String
    let limit: String
    let remaining: String
    let percentSpent: Double
    let health: BudgetHealth

    @State private var animatedProgress: Double = 0

    private var progressColor: Color {
        switch health {
        case .excellent, .good: return BobaColors.limeCream
        case .caution: return BobaColors.metallicGold
        case .warning, .overBudget: return BobaColors.fieryTerracotta
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.sm) {
            // Header
            HStack(spacing: BobaSpacing.xs) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: categoryColorHex))
                    .frame(width: 32, height: 32)
                    .background(Color(hex: categoryColorHex).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: BobaRadius.sm))

                Text(categoryName)
                    .font(BobaFont.headlineSmall())
                    .foregroundStyle(BobaColors.textPrimary)

                Spacer()

                Text(health.message)
                    .font(BobaFont.caption())
                    .foregroundStyle(progressColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(progressColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(BobaColors.surfaceSecondary)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geo.size.width * min(animatedProgress, 1.0), height: 8)
                        .shadow(color: progressColor.opacity(0.4), radius: 4, y: 1)
                }
            }
            .frame(height: 8)

            // Footer: spent / limit
            HStack {
                Text(spent)
                    .font(BobaFont.amountTiny())
                    .foregroundStyle(BobaColors.textPrimary)

                Text("of \(limit)")
                    .font(BobaFont.bodySmall())
                    .foregroundStyle(BobaColors.textTertiary)

                Spacer()

                Text("\(remaining) left")
                    .font(BobaFont.amountTiny())
                    .foregroundStyle(progressColor)
            }
        }
        .padding(BobaSpacing.md)
        .background(BobaColors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.lg))
        .shadow(color: BobaShadow.cardShadow, radius: BobaShadow.cardShadowRadius, y: 4)
        .onAppear {
            withAnimation(BobaAnimation.slow) {
                animatedProgress = percentSpent
            }
        }
        .onChange(of: percentSpent) { _, newValue in
            withAnimation(BobaAnimation.standard) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        BudgetCard(
            categoryName: "Groceries",
            categoryIcon: "cart.fill",
            categoryColorHex: "ddb967",
            spent: "€280",
            limit: "€400",
            remaining: "€120",
            percentSpent: 0.7,
            health: .good
        )
        BudgetCard(
            categoryName: "Dining",
            categoryIcon: "fork.knife",
            categoryColorHex: "d1603d",
            spent: "€180",
            limit: "€200",
            remaining: "€20",
            percentSpent: 0.9,
            health: .warning
        )
    }
    .padding()
    .background(BobaColors.background)
}
