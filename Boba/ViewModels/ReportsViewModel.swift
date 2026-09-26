import Foundation
import SwiftData

/// Powers the Reports tab — spending analysis with chart data.
@Observable
final class ReportsViewModel {
    private let transactionRepo: TransactionRepository
    private let currencyService = CurrencyService.shared

    var categoryBreakdown: [CategorySpending] = []
    var dailySpending: [DailySpending] = []
    var monthlyComparison: [MonthlyTotal] = []
    var totalIncome: Decimal = 0
    var totalExpenses: Decimal = 0
    var primaryCurrency: String = "EUR"
    var selectedPeriod: ReportPeriod = .thisMonth {
        didSet { refresh() }
    }
    var isLoading = false

    struct CategorySpending: Identifiable {
        let id: UUID
        let categoryName: String
        let categoryIcon: String
        let categoryColorHex: String
        let amount: Decimal
        let percentage: Double
    }

    struct DailySpending: Identifiable {
        let id = UUID()
        let date: Date
        let amount: Decimal
    }

    struct MonthlyTotal: Identifiable {
        let id = UUID()
        let month: Date
        let income: Decimal
        let expenses: Decimal
    }

    enum ReportPeriod: String, CaseIterable, Identifiable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case last3Months = "3 Months"
        case thisYear = "This Year"

        var id: String { rawValue }

        var dateRange: (start: Date, end: Date) {
            let now = Date()
            let calendar = Calendar.current
            switch self {
            case .thisWeek:
                return (now.startOfWeek, now)
            case .thisMonth:
                return (now.startOfMonth, now)
            case .lastMonth:
                let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
                return (lastMonth.startOfMonth, lastMonth.endOfMonth)
            case .last3Months:
                let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
                return (threeMonthsAgo.startOfMonth, now)
            case .thisYear:
                return (now.startOfYear, now)
            }
        }
    }

    init(modelContext: ModelContext) {
        self.transactionRepo = TransactionRepository(modelContext: modelContext)
    }

    func refresh() {
        isLoading = true

        let range = selectedPeriod.dateRange

        // Totals
        totalIncome = transactionRepo.totalForPeriod(start: range.start, end: range.end, type: .income)
        totalExpenses = transactionRepo.totalForPeriod(start: range.start, end: range.end, type: .expense)

        // Category breakdown
        let byCategory = transactionRepo.totalByCategory(start: range.start, end: range.end)
        let totalForPercent = byCategory.reduce(Decimal.zero) { $0 + $1.total }

        categoryBreakdown = byCategory.map { item in
            let percent = totalForPercent > 0
                ? NSDecimalNumber(decimal: item.total / totalForPercent).doubleValue
                : 0
            return CategorySpending(
                id: item.category.id,
                categoryName: item.category.name,
                categoryIcon: item.category.icon,
                categoryColorHex: item.category.colorHex,
                amount: item.total,
                percentage: percent
            )
        }

        // Daily spending trend
        let dailyTotals = transactionRepo.dailyTotals(start: range.start, end: range.end, type: .expense)
        dailySpending = dailyTotals.map { DailySpending(date: $0.date, amount: $0.total) }

        // Monthly comparison (last 6 months)
        let calendar = Calendar.current
        monthlyComparison = (0..<6).reversed().compactMap { monthsAgo in
            guard let monthDate = calendar.date(byAdding: .month, value: -monthsAgo, to: Date()) else { return nil }
            let start = monthDate.startOfMonth
            let end = monthDate.endOfMonth
            let income = transactionRepo.totalForPeriod(start: start, end: end, type: .income)
            let expenses = transactionRepo.totalForPeriod(start: start, end: end, type: .expense)
            return MonthlyTotal(month: start, income: income, expenses: expenses)
        }

        isLoading = false
    }

    // MARK: - Formatted

    var formattedIncome: String {
        currencyService.format(totalIncome, currencyCode: primaryCurrency)
    }

    var formattedExpenses: String {
        currencyService.format(totalExpenses, currencyCode: primaryCurrency)
    }

    var netAmount: Decimal {
        totalIncome - totalExpenses
    }

    var formattedNet: String {
        currencyService.format(netAmount, currencyCode: primaryCurrency, showSign: true)
    }

    func formattedAmount(_ amount: Decimal) -> String {
        currencyService.format(amount, currencyCode: primaryCurrency)
    }
}
