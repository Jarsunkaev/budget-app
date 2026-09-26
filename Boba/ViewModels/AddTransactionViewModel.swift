import Foundation
import SwiftData

/// Powers the quick add transaction flow.
/// Designed for under-5-second expense logging.
@Observable
final class AddTransactionViewModel {
    private let transactionRepo: TransactionRepository
    private let categoryRepo: CategoryRepository
    private let accountRepo: AccountRepository

    // MARK: - Form State

    var amountString: String = ""
    var type: TransactionType = .expense
    var selectedCategory: Category?
    var selectedAccount: Account?
    var note: String = ""
    var date: Date = .now
    var isRecurring: Bool = false
    var currencyCode: String = "EUR"

    // Data
    var categories: [Category] = []
    var accounts: [Account] = []
    var isSaving = false

    var amount: Decimal {
        Decimal(string: amountString) ?? 0
    }

    var isValid: Bool {
        amount > 0
    }

    var formattedAmount: String {
        CurrencyService.shared.format(amount, currencyCode: currencyCode)
    }

    init(modelContext: ModelContext) {
        self.transactionRepo = TransactionRepository(modelContext: modelContext)
        self.categoryRepo = CategoryRepository(modelContext: modelContext)
        self.accountRepo = AccountRepository(modelContext: modelContext)
    }

    func loadData() {
        categories = categoryRepo.fetchAll()
        accounts = accountRepo.fetchActive()

        // Default to first account if available
        if selectedAccount == nil {
            selectedAccount = accounts.first
            currencyCode = selectedAccount?.currencyCode ?? CurrencyService.deviceCurrencyCode
        }
    }

    // MARK: - Numpad Input

    func appendDigit(_ digit: String) {
        // Prevent multiple decimal points
        if digit == "." && amountString.contains(".") { return }

        // Limit to 2 decimal places
        if let dotIndex = amountString.firstIndex(of: ".") {
            let decimals = amountString[amountString.index(after: dotIndex)...]
            if decimals.count >= 2 { return }
        }

        // Prevent leading zeros (except "0.")
        if amountString == "0" && digit != "." {
            amountString = digit
            return
        }

        amountString += digit
        BobaHaptics.light()
    }

    func deleteLastDigit() {
        guard !amountString.isEmpty else { return }
        amountString.removeLast()
        BobaHaptics.light()
    }

    func clearAmount() {
        amountString = ""
    }

    // MARK: - Save

    func save() -> Bool {
        guard isValid else { return false }

        isSaving = true

        _ = transactionRepo.create(
            amount: amount,
            currencyCode: currencyCode,
            type: type,
            note: note,
            date: date,
            category: selectedCategory,
            account: selectedAccount
        )

        BobaHaptics.success()
        isSaving = false
        return true
    }

    // MARK: - Reset

    func reset() {
        amountString = ""
        type = .expense
        selectedCategory = nil
        note = ""
        date = .now
        isRecurring = false
    }

    // MARK: - Category filtering by type

    var filteredCategories: [Category] {
        switch type {
        case .expense:
            return categories.filter { $0.type == .need || $0.type == .want }
        case .income:
            return categories // All categories can receive income
        case .transfer:
            return [] // Transfers don't need categories
        }
    }
}
