import SwiftUI
import SwiftData

/// The main Dashboard screen — the "nerve center" of Boba.
/// Shows safe-to-spend, spending ring, quick actions, recent transactions, and budget health.
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?
    @State private var showAddTransaction = false
    @State private var addTransactionType: TransactionType = .expense

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BobaSpacing.xl) {
                    // Hero section
                    heroSection

                    // Quick actions
                    quickActions

                    // Income / Expense summary
                    summaryPills

                    // Budget categories (horizontal scroll)
                    budgetSection

                    // Recent transactions
                    recentTransactionsSection
                }
                .padding(.horizontal, BobaSpacing.md)
                .padding(.bottom, BobaSpacing.xxxl)
            }
            .background(BobaColors.background)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if viewModel == nil {
                    viewModel = DashboardViewModel(modelContext: modelContext)
                }
                viewModel?.refresh()
            }
            .refreshable {
                viewModel?.refresh()
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView(
                    initialType: addTransactionType,
                    onSave: {
                        viewModel?.refresh()
                    }
                )
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        BobaCard {
            VStack(spacing: BobaSpacing.lg) {
                // Spending ring with safe-to-spend in the center
                ZStack {
                    SpendingRing(
                        progress: viewModel?.spendingRatio ?? 0,
                        health: viewModel?.overallHealth ?? .excellent,
                        lineWidth: 12,
                        size: 160
                    )

                    VStack(spacing: BobaSpacing.xxs) {
                        Text("SAFE TO SPEND")
                            .font(BobaFont.overline())
                            .foregroundStyle(BobaColors.textTertiary)
                            .tracking(1.2)

                        Text(viewModel?.formattedSafeToSpend ?? "€0.00")
                            .font(BobaFont.displayMedium())
                            .foregroundStyle(BobaColors.textPrimary)
                            .contentTransition(.numericText())
                    }
                }
                .padding(.top, BobaSpacing.xs)

                // Daily budget hint
                HStack(spacing: BobaSpacing.xxs) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(BobaColors.textTertiary)

                    Text("~\(viewModel?.formattedDailyBudget ?? "€0") / day · \(viewModel?.daysRemaining ?? 0) days left")
                        .font(BobaFont.bodySmall())
                        .foregroundStyle(BobaColors.textTertiary)
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: BobaSpacing.xxl) {
            QuickActionButton(
                icon: "arrow.up.circle.fill",
                label: "Expense",
                color: BobaColors.fieryTerracotta
            ) {
                addTransactionType = .expense
                showAddTransaction = true
            }

            QuickActionButton(
                icon: "arrow.down.circle.fill",
                label: "Income",
                color: BobaColors.limeCream
            ) {
                addTransactionType = .income
                showAddTransaction = true
            }

            QuickActionButton(
                icon: "arrow.left.arrow.right.circle.fill",
                label: "Transfer",
                color: BobaColors.metallicGold
            ) {
                addTransactionType = .transfer
                showAddTransaction = true
            }
        }
    }

    // MARK: - Summary Pills

    private var summaryPills: some View {
        HStack(spacing: BobaSpacing.sm) {
            IncomeExpensePill(
                label: "Income",
                amount: viewModel?.formattedIncome ?? "€0",
                type: .income
            )
            IncomeExpensePill(
                label: "Expenses",
                amount: viewModel?.formattedExpenses ?? "€0",
                type: .expense
            )
            Spacer()
        }
    }

    // MARK: - Budget Section

    @ViewBuilder
    private var budgetSection: some View {
        if let vm = viewModel, !vm.budgetSummaries.isEmpty {
            VStack(alignment: .leading, spacing: BobaSpacing.sm) {
                BobaSectionHeader(title: "Budgets")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: BobaSpacing.sm) {
                        ForEach(vm.budgetSummaries) { summary in
                            BudgetCard(
                                categoryName: summary.categoryName,
                                categoryIcon: summary.categoryIcon,
                                categoryColorHex: summary.categoryColor,
                                spent: CurrencyService.shared.format(summary.spent, currencyCode: vm.primaryCurrency),
                                limit: CurrencyService.shared.format(summary.limit, currencyCode: vm.primaryCurrency),
                                remaining: CurrencyService.shared.format(summary.remaining, currencyCode: vm.primaryCurrency),
                                percentSpent: summary.percentSpent,
                                health: summary.health
                            )
                            .frame(width: 280)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Transactions

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.sm) {
            BobaSectionHeader(title: "Recent")

            if let vm = viewModel {
                if vm.recentTransactions.isEmpty {
                    emptyState
                } else {
                    BobaCard {
                        VStack(spacing: 0) {
                            ForEach(vm.recentTransactions, id: \.id) { transaction in
                                TransactionRow(
                                    transaction: transaction,
                                    currencyCode: vm.primaryCurrency
                                )
                                if transaction.id != vm.recentTransactions.last?.id {
                                    Divider()
                                        .background(BobaColors.surfaceSecondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        BobaCard {
            VStack(spacing: BobaSpacing.md) {
                Image(systemName: "plus.circle.dashed")
                    .font(.system(size: 40))
                    .foregroundStyle(BobaColors.textTertiary)

                Text("No transactions yet")
                    .font(BobaFont.headlineSmall())
                    .foregroundStyle(BobaColors.textSecondary)

                Text("Tap the + button to log your first expense")
                    .font(BobaFont.bodySmall())
                    .foregroundStyle(BobaColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BobaSpacing.lg)
        }
    }
}
