import SwiftUI
import SwiftData

/// Currency management & multi-currency switcher.
/// Allows users to switch their primary currency view and manage enabled currencies.
struct CurrencySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @State private var searchText: String = ""

    private var prefs: UserPreferences? { preferences.first }

    private var allCurrencies: [(code: String, name: String, symbol: String)] {
        CurrencyService.commonCurrencies
    }

    private var filteredCurrencies: [(code: String, name: String, symbol: String)] {
        if searchText.isEmpty {
            return allCurrencies
        }
        return allCurrencies.filter { item in
            item.code.localizedCaseInsensitiveContains(searchText) ||
            item.name.localizedCaseInsensitiveContains(searchText) ||
            item.symbol.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var activeCurrencyCode: String {
        prefs?.primaryCurrencyCode ?? "EUR"
    }

    var body: some View {
        List {
            // Active Currency Card
            Section {
                activeCurrencyHero
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // Description Header
            Section {
                VStack(alignment: .leading, spacing: BobaSpacing.xxs) {
                    Text("MULTI-CURRENCY PERSPECTIVE")
                        .font(BobaFont.overline())
                        .foregroundStyle(BobaColors.textTertiary)
                        .tracking(1.0)

                    Text("Switch your active currency view anytime. Your accounts and budgets are displayed seamlessly in the chosen perspective.")
                        .font(BobaFont.bodySmall())
                        .foregroundStyle(BobaColors.textSecondary)
                }
                .padding(.vertical, BobaSpacing.xs)
            }
            .listRowBackground(Color.clear)

            // Currency List
            Section("Available Currencies") {
                ForEach(filteredCurrencies, id: \.code) { item in
                    currencyRow(item)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(BobaColors.background)
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search by code or country")
    }

    // MARK: - Active Currency Hero

    private var activeCurrencyHero: some View {
        BobaCard {
            HStack(spacing: BobaSpacing.md) {
                ZStack {
                    Circle()
                        .fill(BobaColors.limeCream.opacity(0.18))
                        .frame(width: 50, height: 50)

                    Text(CurrencyService.shared.symbol(for: activeCurrencyCode))
                        .font(BobaFont.displaySmall())
                        .foregroundStyle(BobaColors.limeCream)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("ACTIVE CURRENCY")
                        .font(BobaFont.overline())
                        .foregroundStyle(BobaColors.textTertiary)
                        .tracking(1)

                    Text("\(activeCurrencyCode) — \(currencyName(for: activeCurrencyCode))")
                        .font(BobaFont.headlineSmall())
                        .foregroundStyle(BobaColors.textPrimary)

                    Text("Example format: \(CurrencyService.shared.format(1250.50, currencyCode: activeCurrencyCode))")
                        .font(BobaFont.caption())
                        .foregroundStyle(BobaColors.textTertiary)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(BobaColors.limeCream)
            }
        }
        .padding(.horizontal, BobaSpacing.md)
        .padding(.top, BobaSpacing.sm)
    }

    // MARK: - Currency Row

    private func currencyRow(_ item: (code: String, name: String, symbol: String)) -> some View {
        let isSelected = activeCurrencyCode == item.code

        return Button {
            selectCurrency(item.code)
        } label: {
            HStack(spacing: BobaSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: BobaRadius.sm)
                        .fill(isSelected ? BobaColors.limeCream.opacity(0.2) : BobaColors.surfaceSecondary)
                        .frame(width: 44, height: 44)

                    Text(item.symbol)
                        .font(BobaFont.headlineLarge())
                        .foregroundStyle(isSelected ? BobaColors.limeCream : BobaColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: BobaSpacing.xs) {
                        Text(item.code)
                            .font(BobaFont.headlineSmall())
                            .foregroundStyle(BobaColors.textPrimary)

                        if isSelected {
                            Text("Active")
                                .font(BobaFont.caption())
                                .foregroundStyle(BobaColors.limeCream)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(BobaColors.limeCream.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    Text(item.name)
                        .font(BobaFont.bodySmall())
                        .foregroundStyle(BobaColors.textTertiary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(BobaColors.limeCream)
                }
            }
        }
        .listRowBackground(isSelected ? BobaColors.surfaceElevated : BobaColors.surfacePrimary)
    }

    // MARK: - Helpers

    private func currencyName(for code: String) -> String {
        allCurrencies.first(where: { $0.code == code })?.name ?? "Currency"
    }

    private func selectCurrency(_ code: String) {
        if let p = prefs {
            p.primaryCurrencyCode = code
            var codes = p.additionalCurrencyCodes
            if !codes.contains(code) {
                codes.append(code)
                p.additionalCurrencyCodes = codes
            }
            try? modelContext.save()
            NotificationCenter.default.post(name: .bobaDataDidChange, object: nil)
            BobaHaptics.success()
        }
    }
}
