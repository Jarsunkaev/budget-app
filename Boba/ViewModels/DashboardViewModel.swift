import Foundation
import SwiftData

/// Powers the Dashboard screen — the "nerve center" of the app.
/// Provides safe-to-spend, spending overview, recent transactions,
/// and budget category health at a glance.
@Observable
final class DashboardViewModel {
    private let transactionRepo: TransactionRepository
    private let budgetRepo: BudgetRepository
    private let accountRepo: AccountRepository
    private let currencyService = CurrencyService.shared

    // MARK: - Published State

    var safeToSpend: Decimal = 0
    var totalIncome: Decimal = 0
    var totalExpenses: Decimal = 0
    var recentTransactions: [Transaction] = []
    var budgetSummaries: [BudgetSummary] = []
    var primaryCurrency: String = "EUR"
    var daysRemaining: Int = 0
    var dailyBudget: Decimal = 0
    var overallHealth: BudgetHealth = .excellent
    var isLoading = false

    struct BudgetSummary: Identifiable {
        let id: UUID
        let categoryName: String
        let categoryIcon: String
        let categoryColor: String
        let limit: Decimal
        let spent: Decimal
        let remaining: Decimal
        let percentSpent: Double
        let health: BudgetHealth
    }

    init(modelContext: ModelContext) {
        self.transactionRepo = TransactionRepository(modelContext: modelContext)
        self.budgetRepo = BudgetRepository(modelContext: modelContext)
        self.accountRepo = AccountRepository(modelContext: modelContext)
    }

    // MARK: - Data Loading

    func refresh() {
        isLoading = true

        let now = Date()
        let monthStart = now.startOfMonth
        let monthEnd = now.endOfMonth

        // Income & expenses for current month
        totalIncome = transactionRepo.totalForPeriod(start: monthStart, end: monthEnd, type: .income)
        totalExpenses = transactionRepo.totalForPeriod(start: monthStart, end: monthEnd, type: .expense)

        // Safe to spend = total budget limits - total spent
        let budgets = budgetRepo.fetchAll()
        let allTransactions = transactionRepo.fetchForPeriod(start: monthStart, end: monthEnd)
        let totalLimit = budgets.reduce(Decimal.zero) { $0 + $1.limitAmount }
        let totalSpent = budgets.reduce(Decimal.zero) { $0 + $1.spentAmount(transactions: allTransactions) }
        safeToSpend = totalLimit - totalSpent

        // If no budgets set, fallback to income - expenses
        if budgets.isEmpty {
            safeToSpend = totalIncome - totalExpenses
        }

        // Days remaining and daily budget
        daysRemaining = max(now.daysRemainingInMonth, 1)
        dailyBudget = safeToSpend > 0 ? safeToSpend / Decimal(daysRemaining) : 0

        // Overall health
        if totalLimit > 0 {
            let overallPercent = NSDecimalNumber(decimal: totalSpent / totalLimit).doubleValue
            overallHealth = BudgetHealth(percentSpent: overallPercent)
        }

        // Recent transactions
        recentTransactions = transactionRepo.fetchRecent(limit: 5)

        // Budget summaries
        budgetSummaries = budgets.compactMap { budget in
            guard let cat = budget.category else { return nil }
            let spent = budget.spentAmount(transactions: allTransactions)
            let remaining = budget.remainingAmount(transactions: allTransactions)
            let percent = budget.percentSpent(transactions: allTransactions)

            return BudgetSummary(
                id: budget.id,
                categoryName: cat.name,
                categoryIcon: cat.icon,
                categoryColor: cat.colorHex,
                limit: budget.limitAmount,
                spent: spent,
                remaining: remaining,
                percentSpent: percent,
                health: budget.health(transactions: allTransactions)
            )
        }

        isLoading = false
    }

    // MARK: - Formatted Values

    var formattedSafeToSpend: String {
        currencyService.format(safeToSpend, currencyCode: primaryCurrency)
    }

    var formattedIncome: String {
        currencyService.format(totalIncome, currencyCode: primaryCurrency)
    }

    var formattedExpenses: String {
        currencyService.format(totalExpenses, currencyCode: primaryCurrency)
    }

    var formattedDailyBudget: String {
        currencyService.format(dailyBudget, currencyCode: primaryCurrency)
    }

    var spendingRatio: Double {
        guard totalIncome > 0 else { return 0 }
        return min(NSDecimalNumber(decimal: totalExpenses / totalIncome).doubleValue, 1.5)
    }
}
