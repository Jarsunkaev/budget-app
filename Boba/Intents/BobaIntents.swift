import AppIntents
import SwiftData

// MARK: - Log Expense Intent

/// "Hey Siri, log $15 for coffee in Boba"
struct LogExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Expense"
    static var description: IntentDescription = "Quickly log an expense in Boba"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Category Name")
    var categoryName: String?

    @Parameter(title: "Note")
    var note: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Transaction.self, Category.self, Account.self)
        let context = container.mainContext

        // Find category if provided
        var category: Category?
        if let name = categoryName {
            let descriptor = FetchDescriptor<Category>()
            let categories = (try? context.fetch(descriptor)) ?? []
            category = categories.first { $0.name.lowercased() == name.lowercased() }
        }

        // Find default account
        let accountDescriptor = FetchDescriptor<Account>()
        let account = (try? context.fetch(accountDescriptor))?.first

        // Create transaction
        let transaction = Transaction(
            amount: Decimal(amount),
            currencyCode: account?.currencyCode ?? "EUR",
            type: .expense,
            note: note ?? "",
            category: category,
            account: account
        )
        context.insert(transaction)
        try? context.save()

        let categoryLabel = category?.name ?? "uncategorized"
        let formatted = CurrencyService.shared.format(Decimal(amount), currencyCode: account?.currencyCode ?? "EUR")

        return .result(dialog: "Logged \(formatted) for \(categoryLabel) ✅")
    }
}

// MARK: - Check Budget Intent

/// "Hey Siri, how's my food budget?"
struct CheckBudgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Budget"
    static var description: IntentDescription = "Check how much budget remains for a category"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Category Name")
    var categoryName: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Budget.self, Transaction.self, Category.self)
        let context = container.mainContext

        // Find category
        let catDescriptor = FetchDescriptor<Category>()
        let categories = (try? context.fetch(catDescriptor)) ?? []
        guard let category = categories.first(where: { $0.name.lowercased() == categoryName.lowercased() }) else {
            return .result(dialog: "I couldn't find a category called \"\(categoryName)\"")
        }

        // Find budget
        let budgetDescriptor = FetchDescriptor<Budget>()
        let budgets = (try? context.fetch(budgetDescriptor)) ?? []
        guard let budget = budgets.first(where: { $0.category?.id == category.id }) else {
            return .result(dialog: "No budget set for \(category.name)")
        }

        // Get transactions for current period
        let now = Date()
        let txDescriptor = FetchDescriptor<Transaction>()
        let allTx = (try? context.fetch(txDescriptor)) ?? []
        let spent = budget.spentAmount(transactions: allTx)
        let remaining = budget.remainingAmount(transactions: allTx)
        let currency = budget.currencyCode

        let spentFormatted = CurrencyService.shared.format(spent, currencyCode: currency)
        let remainingFormatted = CurrencyService.shared.format(remaining, currencyCode: currency)
        let limitFormatted = CurrencyService.shared.format(budget.limitAmount, currencyCode: currency)

        let health = budget.health(transactions: allTx)

        return .result(dialog: "\(category.name): \(spentFormatted) spent of \(limitFormatted). \(remainingFormatted) remaining. \(health.message)")
    }
}

// MARK: - Get Safe to Spend Intent

/// "Hey Siri, what can I spend today?"
struct GetSafeToSpendIntent: AppIntent {
    static var title: LocalizedStringResource = "Safe to Spend"
    static var description: IntentDescription = "Check how much you can safely spend"
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Budget.self, Transaction.self)
        let context = container.mainContext

        let now = Date()
        let monthStart = now.startOfMonth
        let monthEnd = now.endOfMonth

        // Get all budgets and transactions
        let budgetDescriptor = FetchDescriptor<Budget>()
        let budgets = (try? context.fetch(budgetDescriptor)) ?? []

        let txPredicate = #Predicate<Transaction> { tx in
            tx.date >= monthStart && tx.date <= monthEnd
        }
        let txDescriptor = FetchDescriptor(predicate: txPredicate)
        let transactions = (try? context.fetch(txDescriptor)) ?? []

        let totalLimit = budgets.reduce(Decimal.zero) { $0 + $1.limitAmount }
        let totalSpent = budgets.reduce(Decimal.zero) { $0 + $1.spentAmount(transactions: transactions) }
        let safeToSpend = totalLimit - totalSpent

        let currency = budgets.first?.currencyCode ?? "EUR"
        let formatted = CurrencyService.shared.format(safeToSpend, currencyCode: currency)

        let daysLeft = max(now.daysRemainingInMonth, 1)
        let daily = safeToSpend / Decimal(daysLeft)
        let dailyFormatted = CurrencyService.shared.format(daily, currencyCode: currency)

        return .result(dialog: "You have \(formatted) safe to spend this month. That's about \(dailyFormatted) per day with \(daysLeft) days left.")
    }
}

// MARK: - Monthly Summary Intent

/// "Hey Siri, my spending this month"
struct MonthlySummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Monthly Summary"
    static var description: IntentDescription = "Get a summary of your spending this month"
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Transaction.self)
        let context = container.mainContext

        let monthStart = Date().startOfMonth
        let incomeType = TransactionType.income
        let expenseType = TransactionType.expense

        let incomePredicate = #Predicate<Transaction> { tx in
            tx.date >= monthStart && tx.type == incomeType
        }
        let expensePredicate = #Predicate<Transaction> { tx in
            tx.date >= monthStart && tx.type == expenseType
        }

        let income = (try? context.fetch(FetchDescriptor(predicate: incomePredicate)))?.reduce(Decimal.zero) { $0 + $1.amount } ?? 0
        let expenses = (try? context.fetch(FetchDescriptor(predicate: expensePredicate)))?.reduce(Decimal.zero) { $0 + $1.amount } ?? 0
        let net = income - expenses
        let currency = "EUR" // Fallback

        let incFormatted = CurrencyService.shared.format(income, currencyCode: currency)
        let expFormatted = CurrencyService.shared.format(expenses, currencyCode: currency)
        let netFormatted = CurrencyService.shared.format(net, currencyCode: currency, showSign: true)

        return .result(dialog: "This month: \(incFormatted) income, \(expFormatted) expenses. Net: \(netFormatted).")
    }
}

// MARK: - App Shortcuts Provider

struct BobaShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Log expense in \(.applicationName)",
                "Add spending in \(.applicationName)"
            ],
            shortTitle: "Log Expense",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: CheckBudgetIntent(),
            phrases: [
                "Check budget in \(.applicationName)",
                "How's my budget in \(.applicationName)"
            ],
            shortTitle: "Check Budget",
            systemImageName: "chart.bar.fill"
        )

        AppShortcut(
            intent: GetSafeToSpendIntent(),
            phrases: [
                "What can I spend today in \(.applicationName)",
                "Safe to spend in \(.applicationName)",
                "How much can I spend in \(.applicationName)"
            ],
            shortTitle: "Safe to Spend",
            systemImageName: "dollarsign.circle.fill"
        )

        AppShortcut(
            intent: MonthlySummaryIntent(),
            phrases: [
                "My spending this month in \(.applicationName)",
                "Monthly summary in \(.applicationName)"
            ],
            shortTitle: "Monthly Summary",
            systemImageName: "chart.pie.fill"
        )
    }
}
