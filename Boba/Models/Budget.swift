import Foundation
import SwiftData

/// A budget allocation for a specific category and time period.
@Model
final class Budget {
    var id: UUID
    var limitAmount: Decimal
    var currencyCode: String
    var period: BudgetPeriod
    var methodology: BudgetMethodology
    var startDate: Date
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    var category: Category?

    init(
        id: UUID = UUID(),
        limitAmount: Decimal,
        currencyCode: String = "EUR",
        period: BudgetPeriod = .monthly,
        methodology: BudgetMethodology = .envelope,
        startDate: Date = .now,
        category: Category? = nil
    ) {
        self.id = id
        self.limitAmount = limitAmount
        self.currencyCode = currencyCode
        self.period = period
        self.methodology = methodology
        self.startDate = startDate
        self.category = category
        self.createdAt = .now
        self.updatedAt = .now
    }

    /// Calculate spent amount from linked transactions within the current period.
    func spentAmount(transactions: [Transaction]) -> Decimal {
        let periodStart = currentPeriodStart
        let periodEnd = currentPeriodEnd

        return transactions
            .filter { tx in
                tx.category?.id == category?.id &&
                tx.type == .expense &&
                tx.date >= periodStart &&
                tx.date <= periodEnd
            }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// Remaining budget for the current period.
    func remainingAmount(transactions: [Transaction]) -> Decimal {
        limitAmount - spentAmount(transactions: transactions)
    }

    /// Percentage of budget spent (0.0 to 1.0+).
    func percentSpent(transactions: [Transaction]) -> Double {
        guard limitAmount > 0 else { return 0 }
        let spent = spentAmount(transactions: transactions)
        return NSDecimalNumber(decimal: spent / limitAmount).doubleValue
    }

    /// Health status based on spending.
    func health(transactions: [Transaction]) -> BudgetHealth {
        BudgetHealth(percentSpent: percentSpent(transactions: transactions))
    }

    // MARK: - Period Calculations

    var currentPeriodStart: Date {
        let calendar = Calendar.current
        switch period {
        case .weekly:
            return calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        case .biweekly:
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
            let weekOfYear = calendar.component(.weekOfYear, from: .now)
            return weekOfYear % 2 == 0 ? weekStart : calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) ?? weekStart
        case .monthly:
            return calendar.dateInterval(of: .month, for: .now)?.start ?? .now
        case .yearly:
            return calendar.dateInterval(of: .year, for: .now)?.start ?? .now
        }
    }

    var currentPeriodEnd: Date {
        let calendar = Calendar.current
        switch period {
        case .weekly:
            return calendar.dateInterval(of: .weekOfYear, for: .now)?.end ?? .now
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: currentPeriodStart) ?? .now
        case .monthly:
            return calendar.dateInterval(of: .month, for: .now)?.end ?? .now
        case .yearly:
            return calendar.dateInterval(of: .year, for: .now)?.end ?? .now
        }
    }
}
