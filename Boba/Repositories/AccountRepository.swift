import Foundation
import SwiftData

/// Data access layer for Account operations.
@Observable
final class AccountRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD

    func create(
        name: String,
        type: AccountType,
        initialBalance: Decimal = 0,
        currencyCode: String = "EUR",
        colorHex: String = "d1603d"
    ) -> Account {
        let account = Account(
            name: name,
            type: type,
            initialBalance: initialBalance,
            currencyCode: currencyCode,
            colorHex: colorHex,
            sortOrder: fetchAll().count
        )
        modelContext.insert(account)
        try? modelContext.save()
        return account
    }

    func delete(_ account: Account) {
        modelContext.delete(account)
        try? modelContext.save()
    }

    func save() {
        try? modelContext.save()
    }

    // MARK: - Queries

    func fetchAll() -> [Account] {
        let descriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchActive() -> [Account] {
        let predicate = #Predicate<Account> { $0.isActive }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.sortOrder)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchByType(_ type: AccountType) -> [Account] {
        let descriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? modelContext.fetch(descriptor))?.filter { $0.type == type } ?? []
    }

    // MARK: - Aggregations

    /// Total balance across all active accounts.
    func totalBalance() -> Decimal {
        fetchActive().reduce(Decimal.zero) { $0 + $1.currentBalance }
    }

    /// Total balance grouped by currency.
    func totalBalanceByCurrency() -> [String: Decimal] {
        var result: [String: Decimal] = [:]
        for account in fetchActive() {
            result[account.currencyCode, default: Decimal.zero] += account.currentBalance
        }
        return result
    }
}
