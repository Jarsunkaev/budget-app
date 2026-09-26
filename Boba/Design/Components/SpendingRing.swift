import SwiftUI

/// Animated spending ring chart component.
/// Used on the Dashboard to show spent vs remaining budget.
struct SpendingRing: View {
    let progress: Double
    let health: BudgetHealth
    var lineWidth: CGFloat = 14
    var size: CGFloat = 180

    @State private var animatedProgress: Double = 0

    private var ringColor: Color {
        switch health {
        case .excellent: return BobaColors.limeCream
        case .good: return BobaColors.limeCream
        case .caution: return BobaColors.metallicGold
        case .warning: return BobaColors.fieryTerracotta
        case .overBudget: return BobaColors.fieryTerracotta
        }
    }

    private var trackColor: Color {
        BobaColors.surfaceSecondary
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Progress
            Circle()
                .trim(from: 0, to: min(animatedProgress, 1.0))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: ringColor.opacity(0.4), radius: 6, x: 0, y: 2)

            // Over-budget glow
            if animatedProgress > 1.0 {
                Circle()
                    .trim(from: 0, to: min(animatedProgress - 1.0, 1.0))
                    .stroke(
                        ringColor.opacity(0.3),
                        style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 4)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(BobaAnimation.slow) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(BobaAnimation.standard) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        SpendingRing(progress: 0.3, health: .excellent)
        SpendingRing(progress: 0.7, health: .good)
        SpendingRing(progress: 0.85, health: .caution)
        SpendingRing(progress: 1.1, health: .overBudget)
    }
    .padding()
    .background(BobaColors.background)
}
