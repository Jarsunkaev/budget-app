import Foundation
import SwiftData

/// Powers the Budgets tab — envelope-style budget tracking with health indicators.
@Observable
final class BudgetOverviewViewModel {
    private let budgetRepo: BudgetRepository
    private let transactionRepo: TransactionRepository
    private let categoryRepo: CategoryRepository
    private let currencyService = CurrencyService.shared

    var budgets: [BudgetItem] = []
    var totalLimit: Decimal = 0
    var totalSpent: Decimal = 0
    var totalRemaining: Decimal = 0
    var overallPercent: Double = 0
    var overallHealth: BudgetHealth = .excellent
    var categories: [Category] = []
    var primaryCurrency: String = "EUR"
    var isLoading = false

    struct BudgetItem: Identifiable {
        let id: UUID
        let budget: Budget
        let categoryName: String
        let categoryIcon: String
        let categoryColorHex: String
        let limit: Decimal
        let spent: Decimal
        let remaining: Decimal
        let percentSpent: Double
        let health: BudgetHealth
        let transactions: [Transaction]
    }

    init(modelContext: ModelContext) {
        self.budgetRepo = BudgetRepository(modelContext: modelContext)
        self.transactionRepo = TransactionRepository(modelContext: modelContext)
        self.categoryRepo = CategoryRepository(modelContext: modelContext)
    }

    func refresh() {
        isLoading = true

        let now = Date()
        let allTransactions = transactionRepo.fetchForPeriod(start: now.startOfMonth, end: now.endOfMonth)
        let allBudgets = budgetRepo.fetchAll()
        categories = categoryRepo.fetchAll()

        budgets = allBudgets.compactMap { budget in
            guard let cat = budget.category else { return nil }
            let spent = budget.spentAmount(transactions: allTransactions)
            let remaining = budget.remainingAmount(transactions: allTransactions)
            let percent = budget.percentSpent(transactions: allTransactions)
            let categoryTx = allTransactions.filter { $0.category?.id == cat.id && $0.type == .expense }

            return BudgetItem(
                id: budget.id,
                budget: budget,
                categoryName: cat.name,
                categoryIcon: cat.icon,
                categoryColorHex: cat.colorHex,
                limit: budget.limitAmount,
                spent: spent,
                remaining: remaining,
                percentSpent: percent,
                health: budget.health(transactions: allTransactions),
                transactions: categoryTx
            )
        }

        totalLimit = allBudgets.reduce(Decimal.zero) { $0 + $1.limitAmount }
        totalSpent = budgets.reduce(Decimal.zero) { $0 + $1.spent }
        totalRemaining = totalLimit - totalSpent
        overallPercent = totalLimit > 0 ? NSDecimalNumber(decimal: totalSpent / totalLimit).doubleValue : 0
        overallHealth = BudgetHealth(percentSpent: overallPercent)

        isLoading = false
    }

    // MARK: - CRUD

    func createBudget(category: Category, limit: Decimal, period: BudgetPeriod, methodology: BudgetMethodology) {
        _ = budgetRepo.create(
            limitAmount: limit,
            currencyCode: primaryCurrency,
            period: period,
            methodology: methodology,
            category: category
        )
        BobaHaptics.success()
        refresh()
    }

    func deleteBudget(_ item: BudgetItem) {
        budgetRepo.delete(item.budget)
        BobaHaptics.medium()
        refresh()
    }

    func updateBudgetLimit(_ item: BudgetItem, newLimit: Decimal) {
        item.budget.limitAmount = newLimit
        item.budget.updatedAt = .now
        budgetRepo.save()
        refresh()
    }

    // MARK: - Formatted Values

    var formattedTotalLimit: String {
        currencyService.format(totalLimit, currencyCode: primaryCurrency)
    }

    var formattedTotalSpent: String {
        currencyService.format(totalSpent, currencyCode: primaryCurrency)
    }

    var formattedTotalRemaining: String {
        currencyService.format(totalRemaining, currencyCode: primaryCurrency)
    }

    func formattedAmount(_ amount: Decimal) -> String {
        currencyService.format(amount, currencyCode: primaryCurrency)
    }
}
