import Foundation
import SwiftData

/// Represents a single financial transaction (income, expense, or transfer).
@Model
final class Transaction {
    var id: UUID
    var amount: Decimal
    var currencyCode: String
    var type: TransactionType
    var note: String
    var date: Date
    var isRecurring: Bool
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    var category: Category?
    var account: Account?
    @Relationship(inverse: \RecurringTransaction.generatedTransactions)
    var recurringTransaction: RecurringTransaction?

    init(
        id: UUID = UUID(),
        amount: Decimal,
        currencyCode: String = "EUR",
        type: TransactionType = .expense,
        note: String = "",
        date: Date = .now,
        isRecurring: Bool = false,
        category: Category? = nil,
        account: Account? = nil,
        recurringTransaction: RecurringTransaction? = nil
    ) {
        self.id = id
        self.amount = amount
        self.currencyCode = currencyCode
        self.type = type
        self.note = note
        self.date = date
        self.isRecurring = isRecurring
        self.category = category
        self.account = account
        self.recurringTransaction = recurringTransaction
        self.createdAt = .now
        self.updatedAt = .now
    }

    /// Signed amount: negative for expenses, positive for income.
    var signedAmount: Decimal {
        switch type {
        case .expense: return -amount
        case .income: return amount
        case .transfer: return -amount
        }
    }
}
