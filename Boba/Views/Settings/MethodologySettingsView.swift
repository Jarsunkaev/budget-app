import SwiftUI
import SwiftData

/// Dedicated view allowing users to switch between budgeting methodologies:
/// - Envelope (Classic digital envelopes)
/// - 50/30/20 (Needs / Wants / Savings)
/// - Zero-Based (Give every dollar a job)
/// - Pay Yourself First (Prioritize savings before spending)
struct MethodologySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @State private var showSavedToast: Bool = false

    private var prefs: UserPreferences? { preferences.first }

    var body: some View {
        ScrollView {
            VStack(spacing: BobaSpacing.lg) {
                // Header description
                headerSection

                // Methodology cards
                ForEach(BudgetMethodology.allCases) { method in
                    methodologyCard(method)
                }
            }
            .padding(.horizontal, BobaSpacing.md)
            .padding(.vertical, BobaSpacing.md)
            .padding(.bottom, 60)
        }
        .background(BobaColors.background)
        .navigationTitle("Budgeting Method")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .overlay(alignment: .bottom) {
            if showSavedToast {
                HStack(spacing: BobaSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(BobaColors.limeCream)
                    Text("Budgeting Method Updated")
                        .font(BobaFont.headlineSmall())
                        .foregroundStyle(BobaColors.textPrimary)
                }
                .padding(.horizontal, BobaSpacing.lg)
                .padding(.vertical, BobaSpacing.sm)
                .background(BobaColors.surfaceElevated)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(BobaColors.limeCream.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
                .padding(.bottom, BobaSpacing.xl)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: BobaSpacing.xs) {
            Text("Choose How You Budget")
                .font(BobaFont.headlineLarge())
                .foregroundStyle(BobaColors.textPrimary)

            Text("Boba adapts its calculations, insights, and targets to match your preferred financial philosophy.")
                .font(BobaFont.bodyMedium())
                .foregroundStyle(BobaColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, BobaSpacing.sm)
    }

    // MARK: - Methodology Card

    private func methodologyCard(_ method: BudgetMethodology) -> some View {
        let isSelected = prefs?.methodology == method

        return Button {
            selectMethodology(method)
        } label: {
            VStack(alignment: .leading, spacing: BobaSpacing.sm) {
                HStack(spacing: BobaSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? BobaColors.limeCream : BobaColors.surfaceElevated)
                            .frame(width: 44, height: 44)

                        Image(systemName: method.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isSelected ? BobaColors.shadowGrey : BobaColors.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(method.displayName)
                                .font(BobaFont.headlineMedium())
                                .foregroundStyle(BobaColors.textPrimary)

                            Spacer()

                            if isSelected {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Active")
                                        .font(BobaFont.caption().bold())
                                }
                                .foregroundStyle(BobaColors.shadowGrey)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(BobaColors.limeCream)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }

                Text(method.description)
                    .font(BobaFont.bodyMedium())
                    .foregroundStyle(BobaColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Sub-feature bullets
                methodBullets(for: method)
            }
            .padding(BobaSpacing.md)
            .background(BobaColors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: BobaRadius.lg)
                    .stroke(isSelected ? BobaColors.limeCream : BobaColors.surfaceSecondary, lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: isSelected ? BobaColors.limeCream.opacity(0.12) : Color.clear, radius: 10, y: 4)
        }
        .buttonStyle(BobaPressableButtonStyle())
    }

    @ViewBuilder
    private func methodBullets(for method: BudgetMethodology) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            switch method {
            case .envelope:
                bulletPoint("Digital cash envelopes per category")
                bulletPoint("Rollover leftover balances to savings")
                bulletPoint("Prevents overspending with hard limits")
            case .fiftyThirtyTwenty:
                bulletPoint("50% Needs (Rent, Utilities, Food)")
                bulletPoint("30% Wants (Entertainment, Dining)")
                bulletPoint("20% Savings & Debt Repayment")
            case .zeroBased:
                bulletPoint("Every dollar has a specified job")
                bulletPoint("Income − Outflow = 0 target balance")
                bulletPoint("Ideal for precision financial planning")
            case .payYourselfFirst:
                bulletPoint("Automatically transfers savings at month start")
                bulletPoint("Spend remaining balance guilt-free")
                bulletPoint("Best for aggressive wealth building")
            }
        }
        .padding(.top, 4)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(spacing: BobaSpacing.xs) {
            Circle()
                .fill(BobaColors.fieryTerracotta)
                .frame(width: 4, height: 4)
            Text(text)
                .font(BobaFont.caption())
                .foregroundStyle(BobaColors.textTertiary)
        }
    }

    private func selectMethodology(_ method: BudgetMethodology) {
        guard let p = prefs else { return }
        p.methodology = method
        try? modelContext.save()
        NotificationCenter.default.post(name: .bobaDataDidChange, object: nil)
        BobaHaptics.success()

        withAnimation(BobaAnimation.quick) {
            showSavedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(BobaAnimation.quick) {
                showSavedToast = false
            }
        }
    }
}
