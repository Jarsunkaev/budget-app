import Foundation
import SwiftData

/// Manages the onboarding flow state and setup logic.
@Observable
final class OnboardingViewModel {
    private var modelContext: ModelContext
    private let categoryRepo: CategoryRepository
    private let accountRepo: AccountRepository

    // MARK: - State

    var currentStep: OnboardingStep = .welcome
    var selectedMethodology: BudgetMethodology = .envelope
    var selectedCurrency: String = CurrencyService.deviceCurrencyCode
    var additionalCurrencies: [String] = []
    var monthlyIncome: String = ""
    var accountName: String = "Checking"
    var accountType: AccountType = .checking
    var accountBalance: String = ""
    var createdAccounts: [AccountPreview] = []
    var enableBiometric: Bool = true
    var isComplete = false

    struct AccountPreview: Identifiable {
        let id = UUID()
        let name: String
        let type: AccountType
        let balance: Decimal
        let currencyCode: String
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.categoryRepo = CategoryRepository(modelContext: modelContext)
        self.accountRepo = AccountRepository(modelContext: modelContext)
    }

    // MARK: - Navigation

    var canAdvance: Bool {
        switch currentStep {
        case .welcome: return true
        case .methodology: return true
        case .accounts: return !createdAccounts.isEmpty || !accountName.isEmpty
        case .currency: return true
        case .categories: return true
        case .biometric: return true
        }
    }

    var isLastStep: Bool {
        currentStep == OnboardingStep.allCases.last
    }

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    func advance() {
        let allSteps = OnboardingStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex < allSteps.count - 1 {
            currentStep = allSteps[currentIndex + 1]
            BobaHaptics.selection()
        }
    }

    func goBack() {
        let allSteps = OnboardingStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex > 0 {
            currentStep = allSteps[currentIndex - 1]
            BobaHaptics.selection()
        }
    }

    // MARK: - Account Management

    func addAccount() {
        let balance = Decimal(string: accountBalance) ?? 0
        let preview = AccountPreview(
            name: accountName,
            type: accountType,
            balance: balance,
            currencyCode: selectedCurrency
        )
        createdAccounts.append(preview)
        // Reset for next entry
        accountName = ""
        accountBalance = ""
        accountType = .checking
        BobaHaptics.success()
    }

    func removeAccount(_ account: AccountPreview) {
        createdAccounts.removeAll { $0.id == account.id }
    }

    // MARK: - Complete Onboarding

    func completeOnboarding() {
        // 1. Seed default categories
        categoryRepo.seedDefaults()

        // 2. Create accounts
        for account in createdAccounts {
            _ = accountRepo.create(
                name: account.name,
                type: account.type,
                initialBalance: account.balance,
                currencyCode: account.currencyCode
            )
        }

        // If no accounts were created, create a default one
        if createdAccounts.isEmpty {
            _ = accountRepo.create(
                name: "Cash",
                type: .cash,
                initialBalance: 0,
                currencyCode: selectedCurrency
            )
        }

        // 3. Save user preferences
        let prefs = UserPreferences(
            methodology: selectedMethodology,
            primaryCurrencyCode: selectedCurrency,
            additionalCurrencyCodes: additionalCurrencies,
            biometricEnabled: enableBiometric,
            hasCompletedOnboarding: true,
            monthlyIncome: Decimal(string: monthlyIncome) ?? 0
        )
        modelContext.insert(prefs)
        try? modelContext.save()

        BobaHaptics.success()
        isComplete = true
    }
}
