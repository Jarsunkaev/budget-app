import SwiftUI
import SwiftData

/// Full transaction list with search, filters, and swipe-to-delete.
struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TransactionListViewModel?
    @State private var showAddTransaction = false
    @State private var showFilters = false

    var body: some View {
        NavigationStack {
            ZStack {
                BobaColors.background.ignoresSafeArea()

                if let vm = viewModel {
                    if vm.filteredTransactions.isEmpty {
                        emptyState
                    } else {
                        transactionList(vm)
                    }
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(
                text: Binding(
                    get: { viewModel?.searchText ?? "" },
                    set: { viewModel?.searchText = $0 }
                ),
                prompt: "Search transactions"
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: BobaSpacing.xs) {
                        // Filter button
                        Button {
                            showFilters.toggle()
                        } label: {
                            Image(systemName: viewModel?.hasActiveFilters == true ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundStyle(viewModel?.hasActiveFilters == true ? BobaColors.fieryTerracotta : BobaColors.textSecondary)
                        }

                        // Add button
                        Button {
                            showAddTransaction = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(BobaColors.fieryTerracotta)
                        }
                    }
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = TransactionListViewModel(modelContext: modelContext)
                }
                viewModel?.refresh()
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView(onSave: { viewModel?.refresh() })
            }
            .sheet(isPresented: $showFilters) {
                filterSheet
            }
        }
    }

    // MARK: - Transaction List

    private func transactionList(_ vm: TransactionListViewModel) -> some View {
        List {
            ForEach(vm.groupedTransactions, id: \.date) { group in
                Section {
                    ForEach(group.transactions, id: \.id) { transaction in
                        TransactionRow(
                            transaction: transaction,
                            currencyCode: vm.primaryCurrency
                        )
                        .listRowBackground(BobaColors.surfacePrimary)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                vm.deleteTransaction(transaction)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    TransactionDayHeader(
                        date: group.date,
                        total: vm.formattedDailyTotal(for: group.date)
                    )
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        NavigationStack {
            List {
                // Transaction type filter
                Section("Type") {
                    ForEach(TransactionType.allCases) { type in
                        Button {
                            if viewModel?.selectedType == type {
                                viewModel?.selectedType = nil
                            } else {
                                viewModel?.selectedType = type
                            }
                        } label: {
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                                Spacer()
                                if viewModel?.selectedType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(BobaColors.fieryTerracotta)
                                }
                            }
                        }
                        .foregroundStyle(BobaColors.textPrimary)
                    }
                }

                // Clear filters
                if viewModel?.hasActiveFilters == true {
                    Section {
                        Button("Clear All Filters") {
                            viewModel?.clearFilters()
                            showFilters = false
                        }
                        .foregroundStyle(BobaColors.fieryTerracotta)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showFilters = false }
                        .foregroundStyle(BobaColors.fieryTerracotta)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: BobaSpacing.lg) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundStyle(BobaColors.textTertiary)

            Text(viewModel?.hasActiveFilters == true ? "No matching transactions" : "No transactions yet")
                .font(BobaFont.headlineMedium())
                .foregroundStyle(BobaColors.textSecondary)

            Text(viewModel?.hasActiveFilters == true
                ? "Try adjusting your filters"
                : "Start by adding your first transaction")
                .font(BobaFont.bodyMedium())
                .foregroundStyle(BobaColors.textTertiary)
                .multilineTextAlignment(.center)

            if viewModel?.hasActiveFilters == true {
                Button("Clear Filters") {
                    viewModel?.clearFilters()
                }
                .font(BobaFont.headlineSmall())
                .foregroundStyle(BobaColors.fieryTerracotta)
            }
        }
        .padding()
    }
}
