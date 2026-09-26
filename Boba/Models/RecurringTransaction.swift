import Foundation
import SwiftData

/// A recurring transaction template that generates transactions automatically.
@Model
final class RecurringTransaction {
    var id: UUID
    var name: String
    var amount: Decimal
    var currencyCode: String
    var type: TransactionType
    var frequency: RecurrenceFrequency
    var nextDueDate: Date
    var endDate: Date?
    var isActive: Bool
    var note: String
    var createdAt: Date

    // Relationships
    var category: Category?
    var account: Account?
    var generatedTransactions: [Transaction]

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        currencyCode: String = "EUR",
        type: TransactionType = .expense,
        frequency: RecurrenceFrequency = .monthly,
        nextDueDate: Date,
        endDate: Date? = nil,
        isActive: Bool = true,
        note: String = "",
        category: Category? = nil,
        account: Account? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.currencyCode = currencyCode
        self.type = type
        self.frequency = frequency
        self.nextDueDate = nextDueDate
        self.endDate = endDate
        self.isActive = isActive
        self.note = note
        self.category = category
        self.account = account
        self.generatedTransactions = []
        self.createdAt = .now
    }

    /// Whether this recurring transaction is due today or overdue.
    var isDue: Bool {
        nextDueDate <= .now
    }

    /// Days until next due date (negative if overdue).
    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: nextDueDate)).day ?? 0
    }

    /// Advance the next due date by the recurrence frequency.
    func advanceNextDueDate() {
        let calendar = Calendar.current
        switch frequency {
        case .daily:
            nextDueDate = calendar.date(byAdding: .day, value: 1, to: nextDueDate) ?? nextDueDate
        case .weekly:
            nextDueDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDueDate) ?? nextDueDate
        case .biweekly:
            nextDueDate = calendar.date(byAdding: .weekOfYear, value: 2, to: nextDueDate) ?? nextDueDate
        case .monthly:
            nextDueDate = calendar.date(byAdding: .month, value: 1, to: nextDueDate) ?? nextDueDate
        case .quarterly:
            nextDueDate = calendar.date(byAdding: .month, value: 3, to: nextDueDate) ?? nextDueDate
        case .yearly:
            nextDueDate = calendar.date(byAdding: .year, value: 1, to: nextDueDate) ?? nextDueDate
        }
    }
}
