import Foundation
import SwiftData

/// Powers the transaction list and filtering.
@Observable
final class TransactionListViewModel {
    private let transactionRepo: TransactionRepository
    private let currencyService = CurrencyService.shared

    var transactions: [Transaction] = []
    var filteredTransactions: [Transaction] = []
    var searchText: String = "" {
        didSet { applyFilters() }
    }
    var selectedType: TransactionType? = nil {
        didSet { applyFilters() }
    }
    var selectedCategory: Category? = nil {
        didSet { applyFilters() }
    }
    var selectedAccount: Account? = nil {
        didSet { applyFilters() }
    }
    var isLoading = false
    var primaryCurrency: String = "EUR"

    /// Transactions grouped by day for section headers.
    var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTransactions) { tx in
            calendar.startOfDay(for: tx.date)
        }
        return grouped
            .map { (date: $0.key, transactions: $0.value) }
            .sorted { $0.date > $1.date }
    }

    init(modelContext: ModelContext) {
        self.transactionRepo = TransactionRepository(modelContext: modelContext)
    }

    func refresh() {
        isLoading = true
        transactions = transactionRepo.fetchAll()
        applyFilters()
        isLoading = false
    }

    func deleteTransaction(_ transaction: Transaction) {
        transactionRepo.delete(transaction)
        refresh()
        BobaHaptics.medium()
    }

    // MARK: - Filtering

    private func applyFilters() {
        var result = transactions

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { tx in
                tx.note.lowercased().contains(query) ||
                tx.category?.name.lowercased().contains(query) == true
            }
        }

        if let type = selectedType {
            result = result.filter { $0.type == type }
        }

        if let category = selectedCategory {
            result = result.filter { $0.category?.id == category.id }
        }

        if let account = selectedAccount {
            result = result.filter { $0.account?.id == account.id }
        }

        filteredTransactions = result
    }

    func clearFilters() {
        searchText = ""
        selectedType = nil
        selectedCategory = nil
        selectedAccount = nil
    }

    var hasActiveFilters: Bool {
        selectedType != nil || selectedCategory != nil || selectedAccount != nil
    }

    // MARK: - Helpers

    func dailyTotal(for date: Date) -> Decimal {
        let calendar = Calendar.current
        return filteredTransactions
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .reduce(Decimal.zero) { $0 + $1.signedAmount }
    }

    func formattedDailyTotal(for date: Date) -> String {
        let total = dailyTotal(for: date)
        return currencyService.format(total, currencyCode: primaryCurrency, showSign: true)
    }
}
