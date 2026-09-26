import SwiftUI
import SwiftData

/// The main Dashboard screen — the "nerve center" of Boba.
/// Shows envelope safe-to-spend, spending ring, quick actions, recent transactions, and budget health.
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?
    @State private var showAddTransaction = false
    @State private var addTransactionType: TransactionType = .expense
    @State private var selectedTransactionForCategorization: Transaction?
    @State private var isSyncingWallet = false
    @State private var walletSyncToast: String? = nil
    @State private var navPath = NavigationPath()

    var onNavigateToBudgets: (() -> Void)? = nil

    var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView {
                VStack(spacing: BobaSpacing.xl) {
                    // Greeting & Profile Header
                    greetingHeader

                    // Hero section (Tap to navigate to Budgets)
                    heroSection

                    // Quick actions: Income -> Expense -> Transfer
                    quickActions

                    // Smart Insights Spending Card
                    aiInsightsSection

                    // Income / Expense summary
                    summaryPills

                    // Budget categories (Tap to navigate to Budgets)
                    budgetSection

                    // Recent transactions (Tap to categorize)
                    recentTransactionsSection
                }
                .padding(.horizontal, BobaSpacing.md)
                .padding(.top, BobaSpacing.xs)
                .padding(.bottom, 85)
            }
            .background(BobaColors.background)
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                if viewModel == nil {
                    viewModel = DashboardViewModel(modelContext: modelContext)
                }
                viewModel?.refresh()
            }
            .refreshable {
                viewModel?.refresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: .bobaDataDidChange)) { _ in
                withAnimation(BobaAnimation.standard) {
                    viewModel?.refresh()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .bobaResetHomeNavigation)) { _ in
                withAnimation(BobaAnimation.quick) {
                    navPath = NavigationPath()
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView(
                    initialType: addTransactionType,
                    onSave: {
                        viewModel?.refresh()
                    }
                )
                .id(addTransactionType)
            }
            .sheet(item: $selectedTransactionForCategorization) { transaction in
                CategorizeTransactionSheet(
                    transaction: transaction,
                    currencyCode: viewModel?.primaryCurrency ?? "EUR",
                    onUpdated: {
                        viewModel?.refresh()
                    }
                )
            }
        }
    }

    // MARK: - Greeting & Dashboard Header

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.xs) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BOBA FINANCIAL")
                        .font(BobaFont.overline())
                        .foregroundStyle(BobaColors.textTertiary)
                        .tracking(1.2)

                    Text("Dashboard")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(BobaColors.textPrimary)
                }

                Spacer()

                NavigationLink {
                    SettingsView()
                } label: {
                    ZStack {
                        Circle()
                            .fill(BobaColors.accentGradient)
                            .frame(width: 42, height: 42)
                            .shadow(color: BobaColors.fieryTerracotta.opacity(0.25), radius: 4, y: 2)

                        Text(viewModel?.userInitials ?? "☕️")
                            .font(BobaFont.headlineSmall())
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(BobaPressableButtonStyle())
            }

            Text(viewModel?.greetingTitle ?? "Welcome back")
                .font(BobaFont.bodyLarge())
                .foregroundStyle(BobaColors.textSecondary)
        }
        .padding(.top, BobaSpacing.md)
    }

    // MARK: - Hero Section: Spending Ring & Safe-to-Spend

    private var heroSection: some View {
        Button {
            triggerBudgetsNavigation()
        } label: {
            BobaCard {
                VStack(spacing: BobaSpacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: BobaSpacing.xxs) {
                            Text("SAFE TO SPEND THIS MONTH")
                                .font(BobaFont.overline())
                                .foregroundStyle(BobaColors.textTertiary)
                                .tracking(1.2)

                            Text(viewModel?.formattedSafeToSpend ?? "0")
                                .font(BobaFont.displayLarge())
                                .foregroundStyle(BobaColors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .contentTransition(.numericText())

                            Text("Daily: \(viewModel?.formattedDailyBudget ?? "0")/day · \(viewModel?.daysLeftInMonth ?? 0) days left")
                                .font(BobaFont.bodySmall())
                                .foregroundStyle(BobaColors.textTertiary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        Spacer()

                        SpendingRing(
                            progress: viewModel?.budgetProgress ?? 0,
                            health: viewModel?.budgetHealth ?? .excellent,
                            lineWidth: 12,
                            size: 100
                        )
                    }

                    // Envelopes Horizontal Scroll (Directly inside hero)
                    if let vm = viewModel, !vm.budgetSummaries.isEmpty {
                        Divider()
                            .background(BobaColors.surfaceSecondary)

                        envelopeHorizontalScroll(envelopes: vm.budgetSummaries, currencyCode: vm.primaryCurrency)
                    }
                }
            }
        }
        .buttonStyle(BobaPressableButtonStyle())
    }

    // MARK: - Envelope Horizontal Scroll

    private func envelopeHorizontalScroll(envelopes: [DashboardViewModel.BudgetSummary], currencyCode: String) -> some View {
        VStack(alignment: .leading, spacing: BobaSpacing.xs) {
            HStack {
                Text("ENVELOPES")
                    .font(BobaFont.overline())
                    .foregroundStyle(BobaColors.textTertiary)
                    .tracking(1)

                Spacer()

                HStack(spacing: 2) {
                    Text("View Budgets")
                        .font(BobaFont.caption())
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(BobaColors.limeCream)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BobaSpacing.sm) {
                    ForEach(envelopes) { env in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: env.categoryIcon)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: env.categoryColor))

                                Text(env.categoryName)
                                    .font(BobaFont.caption().bold())
                                    .foregroundStyle(BobaColors.textPrimary)
                                    .lineLimit(1)

                                Spacer(minLength: 0)

                                Circle()
                                    .fill(envelopeHealthColor(env.health))
                                    .frame(width: 6, height: 6)
                            }

                            Text(CurrencyService.shared.format(env.remaining, currencyCode: currencyCode))
                                .font(BobaFont.headlineSmall())
                                .foregroundStyle(env.remaining >= 0 ? BobaColors.textPrimary : BobaColors.fieryTerracotta)
                                .lineLimit(1)

                            // Mini Progress Bar
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(BobaColors.surfaceSecondary)
                                        .frame(height: 4)

                                    Capsule()
                                        .fill(envelopeHealthColor(env.health))
                                        .frame(width: max(0, min(g.size.width, g.size.width * env.percentSpent)), height: 4)
                                }
                            }
                            .frame(height: 4)

                            Text("of \(CurrencyService.shared.format(env.limit, currencyCode: currencyCode))")
                                .font(BobaFont.caption())
                                .foregroundStyle(BobaColors.textTertiary)
                                .lineLimit(1)
                        }
                        .padding(BobaSpacing.sm)
                        .frame(width: 140)
                        .background(BobaColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: BobaRadius.md)
                                .stroke(BobaColors.surfaceSecondary, lineWidth: 1)
                        )
                    }
                }
                .padding(.top, BobaSpacing.xs)
            }
        }
    }

    private func envelopeHealthColor(_ health: BudgetHealth) -> Color {
        switch health {
        case .excellent, .good: return BobaColors.limeCream
        case .caution: return BobaColors.metallicGold
        case .warning, .overBudget: return BobaColors.fieryTerracotta
        }
    }

    // MARK: - Quick Actions (Order: Income -> Expense -> Transfer)

    private var quickActions: some View {
        HStack(spacing: BobaSpacing.xxl) {
            QuickActionButton(
                icon: "arrow.down.circle.fill",
                label: "Income",
                color: BobaColors.limeCream
            ) {
                BobaHaptics.selection()
                addTransactionType = .income
                showAddTransaction = true
            }

            QuickActionButton(
                icon: "arrow.up.circle.fill",
                label: "Expense",
                color: BobaColors.fieryTerracotta
            ) {
                BobaHaptics.selection()
                addTransactionType = .expense
                showAddTransaction = true
            }

            QuickActionButton(
                icon: "arrow.left.arrow.right.circle.fill",
                label: "Transfer",
                color: BobaColors.metallicGold
            ) {
                BobaHaptics.selection()
                addTransactionType = .transfer
                showAddTransaction = true
            }
        }
    }

    // MARK: - Smart Insights

    @ViewBuilder
    private var aiInsightsSection: some View {
        if let vm = viewModel {
            let insights = FoundationModelsService.shared.generateInsights(
                transactions: vm.recentTransactions,
                budgets: vm.allBudgets,
                categories: vm.allCategories,
                currencyCode: vm.primaryCurrency
            )

            if let first = insights.first {
                BobaCard {
                    HStack(spacing: BobaSpacing.sm) {
                        ZStack {
                            Circle()
                                .fill(BobaColors.metallicGold.opacity(0.18))
                                .frame(width: 40, height: 40)
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(BobaColors.metallicGold)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("SMART INSIGHTS")
                                .font(BobaFont.overline())
                                .foregroundStyle(BobaColors.metallicGold)
                                .tracking(1)

                            Text(first.title)
                                .font(BobaFont.headlineSmall())
                                .foregroundStyle(BobaColors.textPrimary)
                                .lineLimit(1)

                            Text(first.message)
                                .font(BobaFont.bodySmall())
                                .foregroundStyle(BobaColors.textSecondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary Pills

    private var summaryPills: some View {
        HStack(spacing: BobaSpacing.xs) {
            IncomeExpensePill(
                label: "Income",
                amount: viewModel?.formattedIncome ?? "0",
                type: .income
            )
            IncomeExpensePill(
                label: "Expenses",
                amount: viewModel?.formattedExpenses ?? "0",
                type: .expense
            )
            IncomeExpensePill(
                label: "Transfers",
                amount: viewModel?.formattedTransfers ?? "0",
                type: .transfer
            )
        }
    }

    // MARK: - Budget Section

    @ViewBuilder
    private var budgetSection: some View {
        if let vm = viewModel, !vm.budgetSummaries.isEmpty {
            VStack(alignment: .leading, spacing: BobaSpacing.sm) {
                BobaSectionHeader(title: "Budgets", action: {
                    triggerBudgetsNavigation()
                }, actionLabel: "View All")

                VStack(spacing: BobaSpacing.sm) {
                    ForEach(vm.budgetSummaries) { summary in
                        Button {
                            triggerBudgetsNavigation()
                        } label: {
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
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(BobaPressableButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: - Recent Transactions (Tap to Categorize)

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.sm) {
            HStack {
                BobaSectionHeader(title: "Recent Spending")

                Spacer()

                if AppleWalletService.shared.isConnected {
                    Button {
                        Task {
                            isSyncingWallet = true
                            let count = await AppleWalletService.shared.syncRecentTransactions(modelContext: modelContext)
                            isSyncingWallet = false
                            if count > 0 {
                                walletSyncToast = "Synced \(count) Wallet items"
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    walletSyncToast = nil
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            if isSyncingWallet {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(BobaColors.limeCream)
                            } else {
                                AppleWalletAppIcon(size: 16)
                            }
                            Text(isSyncingWallet ? "Syncing..." : (walletSyncToast ?? "Sync Wallet"))
                                .font(BobaFont.caption())
                        }
                        .foregroundStyle(BobaColors.limeCream)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(BobaColors.surfaceElevated)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(BobaColors.surfaceSecondary, lineWidth: 1)
                        )
                    }
                }
            }

            if let vm = viewModel {
                if vm.recentTransactions.isEmpty {
                    emptyState
                } else {
                    BobaCard {
                        VStack(spacing: 0) {
                            ForEach(vm.recentTransactions, id: \.id) { transaction in
                                Button {
                                    selectedTransactionForCategorization = transaction
                                    BobaHaptics.selection()
                                } label: {
                                    TransactionRow(
                                        transaction: transaction,
                                        currencyCode: vm.primaryCurrency
                                    )
                                }
                                .buttonStyle(.plain)

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

    private func triggerBudgetsNavigation() {
        BobaHaptics.selection()
        if let onNavigateToBudgets {
            onNavigateToBudgets()
        } else {
            NotificationCenter.default.post(name: .bobaNavigateToBudgets, object: nil)
        }
    }
}
