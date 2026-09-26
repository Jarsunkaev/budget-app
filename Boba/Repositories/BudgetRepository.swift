import Foundation
import SwiftData

/// Data access layer for Budget operations.
@Observable
final class BudgetRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD

    func create(
        limitAmount: Decimal,
        currencyCode: String,
        period: BudgetPeriod = .monthly,
        methodology: BudgetMethodology = .envelope,
        category: Category? = nil
    ) -> Budget {
        let budget = Budget(
            limitAmount: limitAmount,
            currencyCode: currencyCode,
            period: period,
            methodology: methodology,
            category: category
        )
        modelContext.insert(budget)
        try? modelContext.save()
        return budget
    }

    func delete(_ budget: Budget) {
        modelContext.delete(budget)
        try? modelContext.save()
    }

    func save() {
        try? modelContext.save()
    }

    // MARK: - Queries

    func fetchAll() -> [Budget] {
        let descriptor = FetchDescriptor<Budget>(sortBy: [SortDescriptor(\.category?.sortOrder)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchForCategory(_ category: Category) -> Budget? {
        let categoryId = category.id
        let predicate = #Predicate<Budget> { budget in
            budget.category?.id == categoryId
        }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    func fetchActive() -> [Budget] {
        let descriptor = FetchDescriptor<Budget>(
            sortBy: [SortDescriptor(\.category?.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Aggregations

    func totalBudgetLimit() -> Decimal {
        fetchAll().reduce(Decimal.zero) { $0 + $1.limitAmount }
    }

    func totalBudgetSpent(transactions: [Transaction]) -> Decimal {
        fetchAll().reduce(Decimal.zero) { total, budget in
            total + budget.spentAmount(transactions: transactions)
        }
    }

    func overBudgetCategories(transactions: [Transaction]) -> [Budget] {
        fetchAll().filter { budget in
            budget.percentSpent(transactions: transactions) > 1.0
        }
    }
}
