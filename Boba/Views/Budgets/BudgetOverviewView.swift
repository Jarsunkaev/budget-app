import SwiftUI
import SwiftData

/// Budget overview — envelope-style category progress with overall health.
struct BudgetOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: BudgetOverviewViewModel?
    @State private var showAddBudget = false
    @State private var newBudgetCategory: Category?
    @State private var newBudgetLimit: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BobaSpacing.xl) {
                    // Overall progress
                    overallCard

                    // Category budgets
                    categoryList

                    // Add budget button
                    if viewModel?.categories.isEmpty == false {
                        addBudgetButton
                    }
                }
                .padding(.horizontal, BobaSpacing.md)
                .padding(.bottom, BobaSpacing.xxxl)
            }
            .background(BobaColors.background)
            .navigationTitle("Budgets")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if viewModel == nil {
                    viewModel = BudgetOverviewViewModel(modelContext: modelContext)
                }
                viewModel?.refresh()
            }
            .refreshable {
                viewModel?.refresh()
            }
            .sheet(isPresented: $showAddBudget) {
                addBudgetSheet
            }
        }
    }

    // MARK: - Overall Card

    private var overallCard: some View {
        BobaCard {
            VStack(spacing: BobaSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: BobaSpacing.xxs) {
                        Text("OVERALL BUDGET")
                            .font(BobaFont.overline())
                            .foregroundStyle(BobaColors.textTertiary)
                            .tracking(1.2)

                        Text(viewModel?.formattedTotalRemaining ?? "€0")
                            .font(BobaFont.displaySmall())
                            .foregroundStyle(BobaColors.textPrimary)
                            .contentTransition(.numericText())

                        Text("remaining of \(viewModel?.formattedTotalLimit ?? "€0")")
                            .font(BobaFont.bodySmall())
                            .foregroundStyle(BobaColors.textTertiary)
                    }

                    Spacer()

                    SpendingRing(
                        progress: viewModel?.overallPercent ?? 0,
                        health: viewModel?.overallHealth ?? .excellent,
                        lineWidth: 10,
                        size: 80
                    )
                }

                // Overall progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(BobaColors.surfaceSecondary)
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(healthColor)
                            .frame(width: geo.size.width * min(viewModel?.overallPercent ?? 0, 1.0), height: 12)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("Spent: \(viewModel?.formattedTotalSpent ?? "€0")")
                        .font(BobaFont.bodySmall())
                        .foregroundStyle(BobaColors.textSecondary)
                    Spacer()
                    Text(viewModel?.overallHealth.message ?? "")
                        .font(BobaFont.bodySmall())
                        .foregroundStyle(healthColor)
                }
            }
        }
    }

    private var healthColor: Color {
        switch viewModel?.overallHealth ?? .excellent {
        case .excellent, .good: return BobaColors.limeCream
        case .caution: return BobaColors.metallicGold
        case .warning, .overBudget: return BobaColors.fieryTerracotta
        }
    }

    // MARK: - Category List

    private var categoryList: some View {
        VStack(spacing: BobaSpacing.sm) {
            BobaSectionHeader(title: "Categories")

            if let vm = viewModel {
                if vm.budgets.isEmpty {
                    emptyBudgetState
                } else {
                    ForEach(vm.budgets) { item in
                        BudgetCard(
                            categoryName: item.categoryName,
                            categoryIcon: item.categoryIcon,
                            categoryColorHex: item.categoryColorHex,
                            spent: vm.formattedAmount(item.spent),
                            limit: vm.formattedAmount(item.limit),
                            remaining: vm.formattedAmount(item.remaining),
                            percentSpent: item.percentSpent,
                            health: item.health
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                vm.deleteBudget(item)
                            } label: {
                                Label("Delete Budget", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyBudgetState: some View {
        BobaCard {
            VStack(spacing: BobaSpacing.md) {
                Image(systemName: "envelope.open")
                    .font(.system(size: 40))
                    .foregroundStyle(BobaColors.metallicGold)

                Text("No budgets set")
                    .font(BobaFont.headlineSmall())
                    .foregroundStyle(BobaColors.textSecondary)

                Text("Create budget limits for your categories to start tracking your spending")
                    .font(BobaFont.bodySmall())
                    .foregroundStyle(BobaColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BobaSpacing.lg)
        }
    }

    // MARK: - Add Budget

    private var addBudgetButton: some View {
        Button {
            showAddBudget = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Budget")
            }
            .font(BobaFont.headlineSmall())
            .foregroundStyle(BobaColors.fieryTerracotta)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(BobaColors.fieryTerracotta.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.lg))
        }
    }

    private var addBudgetSheet: some View {
        NavigationStack {
            List {
                Section("Category") {
                    ForEach(viewModel?.categories ?? [], id: \.id) { category in
                        Button {
                            newBudgetCategory = category
                            BobaHaptics.selection()
                        } label: {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundStyle(Color(hex: category.colorHex))
                                Text(category.name)
                                Spacer()
                                if newBudgetCategory?.id == category.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(BobaColors.fieryTerracotta)
                                }
                            }
                        }
                        .foregroundStyle(BobaColors.textPrimary)
                    }
                }

                Section("Monthly Limit") {
                    TextField("Amount", text: $newBudgetLimit)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Button("Create Budget") {
                        guard let category = newBudgetCategory,
                              let limit = Decimal(string: newBudgetLimit),
                              limit > 0 else { return }

                        viewModel?.createBudget(
                            category: category,
                            limit: limit,
                            period: .monthly,
                            methodology: .envelope
                        )
                        showAddBudget = false
                        newBudgetCategory = nil
                        newBudgetLimit = ""
                    }
                    .foregroundStyle(BobaColors.fieryTerracotta)
                    .disabled(newBudgetCategory == nil || newBudgetLimit.isEmpty)
                }
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showAddBudget = false
                    }
                    .foregroundStyle(BobaColors.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
    }
}
