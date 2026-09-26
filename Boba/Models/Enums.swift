import Foundation

// MARK: - Transaction Type

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case income
    case expense
    case transfer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .income: return "Income"
        case .expense: return "Expense"
        case .transfer: return "Transfer"
        }
    }

    var icon: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }
}

// MARK: - Budget Period

enum BudgetPeriod: String, Codable, CaseIterable, Identifiable {
    case weekly
    case biweekly
    case monthly
    case yearly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

// MARK: - Budget Methodology

enum BudgetMethodology: String, Codable, CaseIterable, Identifiable {
    case envelope
    case fiftyThirtyTwenty
    case zeroBased
    case payYourselfFirst

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .envelope: return "Envelope"
        case .fiftyThirtyTwenty: return "50/30/20"
        case .zeroBased: return "Zero-Based"
        case .payYourselfFirst: return "Pay Yourself First"
        }
    }

    var description: String {
        switch self {
        case .envelope:
            return "Allocate fixed amounts to categories. When an envelope is empty, stop spending in that category."
        case .fiftyThirtyTwenty:
            return "50% for needs, 30% for wants, 20% for savings & debt repayment."
        case .zeroBased:
            return "Assign every dollar a job until your income minus expenses equals zero."
        case .payYourselfFirst:
            return "Save first, then spend the rest. Prioritize your future."
        }
    }

    var icon: String {
        switch self {
        case .envelope: return "envelope.fill"
        case .fiftyThirtyTwenty: return "chart.pie.fill"
        case .zeroBased: return "target"
        case .payYourselfFirst: return "banknote.fill"
        }
    }
}

// MARK: - Category Type (for 50/30/20)

enum CategoryType: String, Codable, CaseIterable, Identifiable {
    case need
    case want
    case saving

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .need: return "Need"
        case .want: return "Want"
        case .saving: return "Saving"
        }
    }

    var targetPercentage: Int {
        switch self {
        case .need: return 50
        case .want: return 30
        case .saving: return 20
        }
    }
}

// MARK: - Account Type

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case checking
    case savings
    case creditCard
    case cash
    case investment
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .creditCard: return "Credit Card"
        case .cash: return "Cash"
        case .investment: return "Investment"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .checking: return "building.columns.fill"
        case .savings: return "banknote.fill"
        case .creditCard: return "creditcard.fill"
        case .cash: return "dollarsign.circle.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .other: return "wallet.pass.fill"
        }
    }
}

// MARK: - Recurrence Frequency

enum RecurrenceFrequency: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case biweekly
    case monthly
    case quarterly
    case yearly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
}

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case methodology
    case accounts
    case currency
    case categories
    case biometric

    var title: String {
        switch self {
        case .welcome: return "Welcome to Boba"
        case .methodology: return "Your Style"
        case .accounts: return "Your Accounts"
        case .currency: return "Currency"
        case .categories: return "Categories"
        case .biometric: return "Security"
        }
    }
}

// MARK: - Budget Health

enum BudgetHealth {
    case excellent   // < 50% spent
    case good        // 50-75% spent
    case caution     // 75-90% spent
    case warning     // 90-100% spent
    case overBudget  // > 100% spent

    init(percentSpent: Double) {
        switch percentSpent {
        case ..<0.5: self = .excellent
        case 0.5..<0.75: self = .good
        case 0.75..<0.9: self = .caution
        case 0.9...1.0: self = .warning
        default: self = .overBudget
        }
    }

    var message: String {
        switch self {
        case .excellent: return "Looking great!"
        case .good: return "On track"
        case .caution: return "Getting warm"
        case .warning: return "Almost there"
        case .overBudget: return "Let's adjust"
        }
    }
}
