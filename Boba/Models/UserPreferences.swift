import Foundation
import SwiftData

/// Stores user preferences and app configuration.
@Model
final class UserPreferences {
    var id: UUID
    var methodology: BudgetMethodology
    var primaryCurrencyCode: String
    var additionalCurrencyCodes: [String]
    var notificationsEnabled: Bool
    var budgetWarningThreshold: Double
    var weeklyReportDay: Int
    var biometricEnabled: Bool
    var hasCompletedOnboarding: Bool
    var monthlyIncome: Decimal
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        methodology: BudgetMethodology = .envelope,
        primaryCurrencyCode: String = "EUR",
        additionalCurrencyCodes: [String] = [],
        notificationsEnabled: Bool = true,
        budgetWarningThreshold: Double = 0.8,
        weeklyReportDay: Int = 1, // Sunday
        biometricEnabled: Bool = false,
        hasCompletedOnboarding: Bool = false,
        monthlyIncome: Decimal = 0
    ) {
        self.id = id
        self.methodology = methodology
        self.primaryCurrencyCode = primaryCurrencyCode
        self.additionalCurrencyCodes = additionalCurrencyCodes
        self.notificationsEnabled = notificationsEnabled
        self.budgetWarningThreshold = budgetWarningThreshold
        self.weeklyReportDay = weeklyReportDay
        self.biometricEnabled = biometricEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.monthlyIncome = monthlyIncome
        self.createdAt = .now
        self.updatedAt = .now
    }
}
