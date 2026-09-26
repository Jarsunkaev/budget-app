import SwiftUI
import SwiftData

/// Multi-step onboarding flow: Welcome → Methodology → Accounts → Currency → Biometric.
struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: OnboardingViewModel?
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            BobaColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                progressBar
                    .padding(.top, BobaSpacing.md)
                    .padding(.horizontal, BobaSpacing.md)

                // Step content
                TabView(selection: Binding(
                    get: { viewModel?.currentStep ?? .welcome },
                    set: { viewModel?.currentStep = $0 }
                )) {
                    WelcomeStepView()
                        .tag(OnboardingStep.welcome)

                    if let vm = viewModel {
                        MethodologyStepView(viewModel: vm)
                            .tag(OnboardingStep.methodology)

                        AccountSetupStepView(viewModel: vm)
                            .tag(OnboardingStep.accounts)

                        CurrencyStepView(viewModel: vm)
                            .tag(OnboardingStep.currency)

                        CategoryStepView()
                            .tag(OnboardingStep.categories)

                        BiometricStepView(viewModel: vm)
                            .tag(OnboardingStep.biometric)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(BobaAnimation.standard, value: viewModel?.currentStep)

                // Navigation buttons
                navigationButtons
                    .padding(.horizontal, BobaSpacing.md)
                    .padding(.bottom, BobaSpacing.xxl)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = OnboardingViewModel(modelContext: modelContext)
            }
        }
        .onChange(of: viewModel?.isComplete ?? false) { _, isComplete in
            if isComplete { onComplete() }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(BobaColors.surfaceSecondary)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 3)
                    .fill(BobaColors.fieryTerracotta)
                    .frame(width: geo.size.width * (viewModel?.progress ?? 0), height: 4)
                    .animation(BobaAnimation.standard, value: viewModel?.progress)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack(spacing: BobaSpacing.sm) {
            // Back button
            if viewModel?.currentStep != .welcome {
                Button {
                    viewModel?.goBack()
                } label: {
                    HStack(spacing: BobaSpacing.xxs) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(BobaFont.headlineSmall())
                    .foregroundStyle(BobaColors.textSecondary)
                    .frame(height: 52)
                    .padding(.horizontal, BobaSpacing.lg)
                    .background(BobaColors.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: BobaRadius.lg))
                }
            }

            Spacer()

            // Next / Complete button
            Button {
                if viewModel?.isLastStep == true {
                    viewModel?.completeOnboarding()
                } else {
                    // Auto-add account if fields are filled
                    if viewModel?.currentStep == .accounts &&
                       viewModel?.createdAccounts.isEmpty == true &&
                       !(viewModel?.accountName.isEmpty ?? true) {
                        viewModel?.addAccount()
                    }
                    viewModel?.advance()
                }
            } label: {
                Text(viewModel?.isLastStep == true ? "Get Started" : "Continue")
                    .font(BobaFont.headlineMedium())
                    .foregroundStyle(.white)
                    .frame(height: 52)
                    .frame(maxWidth: viewModel?.currentStep == .welcome ? .infinity : nil)
                    .padding(.horizontal, BobaSpacing.xxl)
                    .background(BobaColors.fieryTerracotta)
                    .clipShape(RoundedRectangle(cornerRadius: BobaRadius.lg))
            }
            .disabled(viewModel?.canAdvance != true)
        }
    }
}

// MARK: - Step Views

struct WelcomeStepView: View {
    @State private var showContent = false

    var body: some View {
        VStack(spacing: BobaSpacing.xxl) {
            Spacer()

            // App icon / emoji
            Text("🧋")
                .font(.system(size: 80))
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1 : 0)

            VStack(spacing: BobaSpacing.sm) {
                Text("Welcome to Boba")
                    .font(BobaFont.displaySmall())
                    .foregroundStyle(BobaColors.textPrimary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Text("Your warm, friendly budget companion.\nLet's set things up in a minute.")
                    .font(BobaFont.bodyLarge())
                    .foregroundStyle(BobaColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }

            // Feature highlights
            VStack(alignment: .leading, spacing: BobaSpacing.md) {
                featureRow(icon: "chart.pie.fill", title: "Track spending", subtitle: "Know where every dollar goes")
                featureRow(icon: "target", title: "Set budgets", subtitle: "Stay on track with envelope-style limits")
                featureRow(icon: "bell.fill", title: "Smart alerts", subtitle: "Friendly nudges, never judgmental")
                featureRow(icon: "wand.and.stars", title: "Siri Shortcuts", subtitle: "Log expenses with your voice")
            }
            .padding(.horizontal, BobaSpacing.xl)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)

            Spacer()
        }
        .onAppear {
            withAnimation(BobaAnimation.slow.delay(0.2)) {
                showContent = true
            }
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: BobaSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BobaColors.fieryTerracotta)
                .frame(width: 36, height: 36)
                .background(BobaColors.fieryTerracotta.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: BobaRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BobaFont.headlineSmall())
                    .foregroundStyle(BobaColors.textPrimary)
                Text(subtitle)
                    .font(BobaFont.bodySmall())
                    .foregroundStyle(BobaColors.textTertiary)
            }
        }
    }
}

struct MethodologyStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: BobaSpacing.xl) {
            Spacer()

            VStack(spacing: BobaSpacing.sm) {
                Text("How do you budget?")
                    .font(BobaFont.displaySmall())
                    .foregroundStyle(BobaColors.textPrimary)

                Text("Pick your style. You can always change this later.")
                    .font(BobaFont.bodyMedium())
                    .foregroundStyle(BobaColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: BobaSpacing.sm) {
                ForEach(BudgetMethodology.allCases) { method in
                    methodCard(method)
                }
            }
            .padding(.horizontal, BobaSpacing.md)

            Spacer()
        }
    }

    private func methodCard(_ method: BudgetMethodology) -> some View {
        let isSelected = viewModel.selectedMethodology == method

        return Button {
            withAnimation(BobaAnimation.quick) {
                viewModel.selectedMethodology = method
            }
            BobaHaptics.selection()
        } label: {
            HStack(spacing: BobaSpacing.md) {
                Image(systemName: method.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? BobaColors.fieryTerracotta : BobaColors.textTertiary)
                    .frame(width: 44, height: 44)
                    .background(
                        isSelected
                            ? BobaColors.fieryTerracotta.opacity(0.15)
                            : BobaColors.surfaceSecondary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))

                VStack(alignment: .leading, spacing: 2) {
                    Text(method.displayName)
                        .font(BobaFont.headlineSmall())
                        .foregroundStyle(BobaColors.textPrimary)

                    Text(method.description)
                        .font(BobaFont.bodySmall())
                        .foregroundStyle(BobaColors.textTertiary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(BobaColors.fieryTerracotta)
                }
            }
            .padding(BobaSpacing.md)
            .background(isSelected ? BobaColors.surfaceElevated : BobaColors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: BobaRadius.lg)
                    .stroke(isSelected ? BobaColors.fieryTerracotta : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct AccountSetupStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: BobaSpacing.xl) {
                VStack(spacing: BobaSpacing.sm) {
                    Text("Your accounts")
                        .font(BobaFont.displaySmall())
                        .foregroundStyle(BobaColors.textPrimary)

                    Text("Add the accounts you want to track.")
                        .font(BobaFont.bodyMedium())
                        .foregroundStyle(BobaColors.textSecondary)
                }

                // Created accounts
                ForEach(viewModel.createdAccounts) { account in
                    HStack {
                        Image(systemName: account.type.icon)
                            .foregroundStyle(BobaColors.fieryTerracotta)
                        Text(account.name)
                            .font(BobaFont.headlineSmall())
                            .foregroundStyle(BobaColors.textPrimary)
                        Spacer()
                        Text(CurrencyService.shared.format(account.balance, currencyCode: account.currencyCode))
                            .font(BobaFont.amountTiny())
                            .foregroundStyle(BobaColors.textSecondary)

                        Button {
                            viewModel.removeAccount(account)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(BobaColors.textTertiary)
                        }
                    }
                    .padding(BobaSpacing.md)
                    .background(BobaColors.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                }

                // New account form
                VStack(spacing: BobaSpacing.sm) {
                    TextField("Account name", text: $viewModel.accountName)
                        .font(BobaFont.bodyLarge())
                        .foregroundStyle(BobaColors.textPrimary)
                        .padding(BobaSpacing.sm)
                        .background(BobaColors.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                        .tint(BobaColors.fieryTerracotta)

                    // Account type picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: BobaSpacing.xs) {
                            ForEach(AccountType.allCases) { type in
                                Button {
                                    viewModel.accountType = type
                                    BobaHaptics.selection()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 12))
                                        Text(type.displayName)
                                            .font(BobaFont.bodySmall())
                                    }
                                    .foregroundStyle(viewModel.accountType == type ? .white : BobaColors.textSecondary)
                                    .padding(.horizontal, BobaSpacing.sm)
                                    .padding(.vertical, BobaSpacing.xs)
                                    .background(viewModel.accountType == type ? BobaColors.fieryTerracotta : BobaColors.surfacePrimary)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    TextField("Initial balance (optional)", text: $viewModel.accountBalance)
                        .keyboardType(.decimalPad)
                        .font(BobaFont.bodyLarge())
                        .foregroundStyle(BobaColors.textPrimary)
                        .padding(BobaSpacing.sm)
                        .background(BobaColors.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                        .tint(BobaColors.fieryTerracotta)

                    Button {
                        viewModel.addAccount()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Account")
                        }
                        .font(BobaFont.headlineSmall())
                        .foregroundStyle(BobaColors.fieryTerracotta)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(BobaColors.fieryTerracotta.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                    }
                    .disabled(viewModel.accountName.isEmpty)
                }
                .padding(.horizontal, BobaSpacing.md)
            }
            .padding(.top, BobaSpacing.xxxl)
        }
    }
}

struct CurrencyStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: BobaSpacing.xl) {
            VStack(spacing: BobaSpacing.sm) {
                Text("Primary currency")
                    .font(BobaFont.displaySmall())
                    .foregroundStyle(BobaColors.textPrimary)

                Text("This is the main currency for your budgets.")
                    .font(BobaFont.bodyMedium())
                    .foregroundStyle(BobaColors.textSecondary)
            }
            .padding(.top, BobaSpacing.xxxl)

            // Currency grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BobaSpacing.xs) {
                    ForEach(CurrencyService.commonCurrencies.prefix(12), id: \.code) { currency in
                        let isSelected = viewModel.selectedCurrency == currency.code
                        Button {
                            viewModel.selectedCurrency = currency.code
                            BobaHaptics.selection()
                        } label: {
                            HStack {
                                Text(currency.symbol)
                                    .font(BobaFont.amountSmall())
                                    .foregroundStyle(isSelected ? BobaColors.fieryTerracotta : BobaColors.textTertiary)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(currency.code)
                                        .font(BobaFont.headlineSmall())
                                        .foregroundStyle(BobaColors.textPrimary)
                                    Text(currency.name)
                                        .font(BobaFont.caption())
                                        .foregroundStyle(BobaColors.textTertiary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(BobaColors.fieryTerracotta)
                                }
                            }
                            .padding(BobaSpacing.sm)
                            .background(isSelected ? BobaColors.surfaceElevated : BobaColors.surfacePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: BobaRadius.md)
                                    .stroke(isSelected ? BobaColors.fieryTerracotta : Color.clear, lineWidth: 1.5)
                            )
                        }
                    }
                }
                .padding(.horizontal, BobaSpacing.md)
            }
        }
    }
}

struct CategoryStepView: View {
    var body: some View {
        VStack(spacing: BobaSpacing.xl) {
            Spacer()

            Image(systemName: "tag.fill")
                .font(.system(size: 50))
                .foregroundStyle(BobaColors.metallicGold)

            VStack(spacing: BobaSpacing.sm) {
                Text("Categories ready!")
                    .font(BobaFont.displaySmall())
                    .foregroundStyle(BobaColors.textPrimary)

                Text("We've set up default spending categories for you.\nYou can customize them anytime in Settings.")
                    .font(BobaFont.bodyMedium())
                    .foregroundStyle(BobaColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Preview some categories
            VStack(spacing: BobaSpacing.xs) {
                ForEach(Category.defaults.prefix(6), id: \.name) { cat in
                    HStack(spacing: BobaSpacing.sm) {
                        Image(systemName: cat.icon)
                            .foregroundStyle(Color(hex: cat.color))
                            .frame(width: 28, height: 28)
                            .background(Color(hex: cat.color).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Text(cat.name)
                            .font(BobaFont.bodyMedium())
                            .foregroundStyle(BobaColors.textPrimary)

                        Spacer()

                        Text(cat.type.displayName)
                            .font(BobaFont.caption())
                            .foregroundStyle(BobaColors.textTertiary)
                    }
                    .padding(.horizontal, BobaSpacing.md)
                    .padding(.vertical, BobaSpacing.xs)
                }
            }
            .padding(BobaSpacing.sm)
            .background(BobaColors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.lg))
            .padding(.horizontal, BobaSpacing.md)

            Text("+ \(Category.defaults.count - 6) more categories")
                .font(BobaFont.bodySmall())
                .foregroundStyle(BobaColors.textTertiary)

            Spacer()
        }
    }
}

struct BiometricStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    private let biometric = BiometricService.shared

    var body: some View {
        VStack(spacing: BobaSpacing.xl) {
            Spacer()

            Image(systemName: biometric.biometricIcon)
                .font(.system(size: 60))
                .foregroundStyle(BobaColors.fieryTerracotta)

            VStack(spacing: BobaSpacing.sm) {
                Text("Secure your data")
                    .font(BobaFont.displaySmall())
                    .foregroundStyle(BobaColors.textPrimary)

                Text("Use \(biometric.biometricName) to keep your financial data private.")
                    .font(BobaFont.bodyMedium())
                    .foregroundStyle(BobaColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Toggle(isOn: $viewModel.enableBiometric) {
                HStack {
                    Image(systemName: biometric.biometricIcon)
                        .foregroundStyle(BobaColors.fieryTerracotta)
                    Text("Enable \(biometric.biometricName)")
                        .font(BobaFont.headlineSmall())
                        .foregroundStyle(BobaColors.textPrimary)
                }
            }
            .tint(BobaColors.fieryTerracotta)
            .padding(BobaSpacing.md)
            .background(BobaColors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.lg))
            .padding(.horizontal, BobaSpacing.xl)

            Spacer()
        }
    }
}
