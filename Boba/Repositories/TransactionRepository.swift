import Foundation
import SwiftData

/// Data access layer for Transaction operations.
/// All SwiftData queries are isolated here for testability.
@Observable
final class TransactionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD

    func create(
        amount: Decimal,
        currencyCode: String,
        type: TransactionType,
        note: String = "",
        date: Date = .now,
        category: Category? = nil,
        account: Account? = nil
    ) -> Transaction {
        let transaction = Transaction(
            amount: amount,
            currencyCode: currencyCode,
            type: type,
            note: note,
            date: date,
            category: category,
            account: account
        )
        modelContext.insert(transaction)
        try? modelContext.save()
        return transaction
    }

    func delete(_ transaction: Transaction) {
        modelContext.delete(transaction)
        try? modelContext.save()
    }

    func save() {
        try? modelContext.save()
    }

    // MARK: - Queries

    func fetchAll(
        sortBy: SortDescriptor<Transaction> = SortDescriptor(\.date, order: .reverse),
        limit: Int? = nil
    ) -> [Transaction] {
        var descriptor = FetchDescriptor<Transaction>(sortBy: [sortBy])
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchForPeriod(start: Date, end: Date, type: TransactionType? = nil) -> [Transaction] {
        let predicate: Predicate<Transaction>
        if let type {
            predicate = #Predicate<Transaction> { tx in
                tx.date >= start && tx.date <= end && tx.type == type
            }
        } else {
            predicate = #Predicate<Transaction> { tx in
                tx.date >= start && tx.date <= end
            }
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchForCategory(_ category: Category, start: Date, end: Date) -> [Transaction] {
        let categoryId = category.id
        let predicate = #Predicate<Transaction> { tx in
            tx.category?.id == categoryId &&
            tx.date >= start && tx.date <= end
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchForAccount(_ account: Account) -> [Transaction] {
        let accountId = account.id
        let predicate = #Predicate<Transaction> { tx in
            tx.account?.id == accountId
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchRecent(limit: Int = 5) -> [Transaction] {
        return fetchAll(limit: limit)
    }

    // MARK: - Aggregations

    func totalForPeriod(start: Date, end: Date, type: TransactionType) -> Decimal {
        fetchForPeriod(start: start, end: end, type: type)
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    func totalByCategory(start: Date, end: Date) -> [(category: Category, total: Decimal)] {
        let transactions = fetchForPeriod(start: start, end: end, type: .expense)
        var totals: [UUID: (category: Category, total: Decimal)] = [:]

        for tx in transactions {
            guard let cat = tx.category else { continue }
            if var existing = totals[cat.id] {
                existing.total += tx.amount
                totals[cat.id] = existing
            } else {
                totals[cat.id] = (category: cat, total: tx.amount)
            }
        }

        return totals.values.sorted { $0.total > $1.total }
    }

    func dailyTotals(start: Date, end: Date, type: TransactionType) -> [(date: Date, total: Decimal)] {
        let transactions = fetchForPeriod(start: start, end: end, type: type)
        let calendar = Calendar.current
        var dailyMap: [Date: Decimal] = [:]

        for tx in transactions {
            let day = calendar.startOfDay(for: tx.date)
            dailyMap[day, default: Decimal.zero] += tx.amount
        }

        return dailyMap
            .map { (date: $0.key, total: $0.value) }
            .sorted { $0.date < $1.date }
    }
}
