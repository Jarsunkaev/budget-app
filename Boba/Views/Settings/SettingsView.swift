import SwiftUI
import SwiftData

/// Settings tab for preferences, accounts, data, and security.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @State private var showExportOptions = false

    private var prefs: UserPreferences? { preferences.first }

    var body: some View {
        NavigationStack {
            List {
                // Profile section
                profileSection

                // Budget settings
                budgetSection

                // Accounts
                accountsSection

                // Notifications
                notificationSection

                // Security
                securitySection

                // Data
                dataSection

                // About
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(BobaColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section {
            HStack(spacing: BobaSpacing.md) {
                ZStack {
                    Circle()
                        .fill(BobaColors.accentGradient)
                        .frame(width: 56, height: 56)

                    Text("🧋")
                        .font(.system(size: 28))
                }

                VStack(alignment: .leading, spacing: BobaSpacing.xxxs) {
                    Text("Boba")
                        .font(BobaFont.headlineLarge())
                        .foregroundStyle(BobaColors.textPrimary)

                    Text("Your personal budget companion")
                        .font(BobaFont.bodySmall())
                        .foregroundStyle(BobaColors.textTertiary)
                }
            }
            .listRowBackground(BobaColors.surfacePrimary)
        }
    }

    // MARK: - Budget

    private var budgetSection: some View {
        Section("Budget") {
            // Methodology
            HStack {
                Label("Method", systemImage: prefs?.methodology.icon ?? "target")
                    .foregroundStyle(BobaColors.textPrimary)
                Spacer()
                Text(prefs?.methodology.displayName ?? "Envelope")
                    .foregroundStyle(BobaColors.textTertiary)
            }
            .listRowBackground(BobaColors.surfacePrimary)

            // Currency
            HStack {
                Label("Currency", systemImage: "dollarsign.circle")
                    .foregroundStyle(BobaColors.textPrimary)
                Spacer()
                Text(prefs?.primaryCurrencyCode ?? "EUR")
                    .foregroundStyle(BobaColors.textTertiary)
            }
            .listRowBackground(BobaColors.surfacePrimary)

            // Monthly income
            HStack {
                Label("Monthly Income", systemImage: "arrow.down.circle")
                    .foregroundStyle(BobaColors.textPrimary)
                Spacer()
                Text(CurrencyService.shared.format(
                    prefs?.monthlyIncome ?? 0,
                    currencyCode: prefs?.primaryCurrencyCode ?? "EUR"
                ))
                .foregroundStyle(BobaColors.textTertiary)
            }
            .listRowBackground(BobaColors.surfacePrimary)
        }
    }

    // MARK: - Accounts

    private var accountsSection: some View {
        Section("Accounts") {
            NavigationLink {
                Text("Account Management")
                    .foregroundStyle(BobaColors.textPrimary)
            } label: {
                Label("Manage Accounts", systemImage: "building.columns")
                    .foregroundStyle(BobaColors.textPrimary)
            }
            .listRowBackground(BobaColors.surfacePrimary)
        }
    }

    // MARK: - Notifications

    private var notificationSection: some View {
        Section("Notifications") {
            Toggle(isOn: Binding(
                get: { prefs?.notificationsEnabled ?? true },
                set: { newValue in
                    prefs?.notificationsEnabled = newValue
                    try? modelContext.save()
                }
            )) {
                Label("Budget Alerts", systemImage: "bell.fill")
                    .foregroundStyle(BobaColors.textPrimary)
            }
            .tint(BobaColors.fieryTerracotta)
            .listRowBackground(BobaColors.surfacePrimary)

            HStack {
                Label("Warning at", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(BobaColors.textPrimary)
                Spacer()
                Text("\(Int((prefs?.budgetWarningThreshold ?? 0.8) * 100))%")
                    .foregroundStyle(BobaColors.textTertiary)
            }
            .listRowBackground(BobaColors.surfacePrimary)
        }
    }

    // MARK: - Security

    private var securitySection: some View {
        Section("Security") {
            Toggle(isOn: Binding(
                get: { prefs?.biometricEnabled ?? false },
                set: { newValue in
                    prefs?.biometricEnabled = newValue
                    try? modelContext.save()
                }
            )) {
                Label(BiometricService.shared.biometricName, systemImage: BiometricService.shared.biometricIcon)
                    .foregroundStyle(BobaColors.textPrimary)
            }
            .tint(BobaColors.fieryTerracotta)
            .listRowBackground(BobaColors.surfacePrimary)
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section("Data") {
            Button {
                showExportOptions = true
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
                    .foregroundStyle(BobaColors.textPrimary)
            }
            .listRowBackground(BobaColors.surfacePrimary)

            NavigationLink {
                Text("Categories")
            } label: {
                Label("Manage Categories", systemImage: "tag")
                    .foregroundStyle(BobaColors.textPrimary)
            }
            .listRowBackground(BobaColors.surfacePrimary)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("Version", systemImage: "info.circle")
                    .foregroundStyle(BobaColors.textPrimary)
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(BobaColors.textTertiary)
            }
            .listRowBackground(BobaColors.surfacePrimary)

            NavigationLink {
                Text("Privacy Policy")
            } label: {
                Label("Privacy Policy", systemImage: "lock.shield")
                    .foregroundStyle(BobaColors.textPrimary)
            }
            .listRowBackground(BobaColors.surfacePrimary)
        }
    }
}
