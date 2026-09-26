import SwiftUI
import SwiftData

/// Quick add transaction screen with numpad-first design.
/// Goal: under 5 seconds to log an expense.
struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddTransactionViewModel?

    var initialType: TransactionType = .expense
    var onSave: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                BobaColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Type selector
                    typeSelector
                        .padding(.top, BobaSpacing.md)

                    Spacer()

                    // Amount display
                    amountDisplay
                        .padding(.bottom, BobaSpacing.lg)

                    // Category picker
                    categoryPicker
                        .padding(.bottom, BobaSpacing.md)

                    // Account selector
                    accountSelector
                        .padding(.bottom, BobaSpacing.md)

                    // Note field
                    noteField
                        .padding(.horizontal, BobaSpacing.md)
                        .padding(.bottom, BobaSpacing.md)

                    // Numpad
                    numpad
                        .padding(.horizontal, BobaSpacing.lg)
                        .padding(.bottom, BobaSpacing.md)

                    // Save button
                    saveButton
                        .padding(.horizontal, BobaSpacing.md)
                        .padding(.bottom, BobaSpacing.lg)
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BobaColors.textSecondary)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = AddTransactionViewModel(modelContext: modelContext)
                    viewModel?.type = initialType
                }
                viewModel?.loadData()
            }
        }
    }

    // MARK: - Type Selector

    private var typeSelector: some View {
        HStack(spacing: BobaSpacing.xxs) {
            ForEach(TransactionType.allCases) { type in
                Button {
                    withAnimation(BobaAnimation.quick) {
                        viewModel?.type = type
                    }
                    BobaHaptics.selection()
                } label: {
                    Text(type.displayName)
                        .font(BobaFont.headlineSmall())
                        .foregroundStyle(viewModel?.type == type ? BobaColors.textOnAccent : BobaColors.textTertiary)
                        .padding(.horizontal, BobaSpacing.md)
                        .padding(.vertical, BobaSpacing.xs)
                        .background(
                            viewModel?.type == type
                                ? BobaColors.fieryTerracotta
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(BobaSpacing.xxs)
        .background(BobaColors.surfacePrimary)
        .clipShape(Capsule())
    }

    // MARK: - Amount Display

    private var amountDisplay: some View {
        VStack(spacing: BobaSpacing.xxs) {
            Text(CurrencyService.shared.symbol(for: viewModel?.currencyCode ?? "EUR"))
                .font(BobaFont.headlineMedium())
                .foregroundStyle(BobaColors.textTertiary)

            Text(viewModel?.amountString.isEmpty == false ? viewModel!.amountString : "0")
                .font(BobaFont.displayLarge())
                .foregroundStyle(
                    viewModel?.amountString.isEmpty == false
                        ? BobaColors.textPrimary
                        : BobaColors.textTertiary
                )
                .contentTransition(.numericText())
                .animation(.default, value: viewModel?.amountString)
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BobaSpacing.xs) {
                ForEach(viewModel?.filteredCategories ?? [], id: \.id) { category in
                    Button {
                        withAnimation(BobaAnimation.quick) {
                            viewModel?.selectedCategory = category
                        }
                        BobaHaptics.selection()
                    } label: {
                        HStack(spacing: BobaSpacing.xxs) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                            Text(category.name)
                                .font(BobaFont.bodySmall())
                        }
                        .foregroundStyle(
                            viewModel?.selectedCategory?.id == category.id
                                ? BobaColors.textOnAccent
                                : BobaColors.textSecondary
                        )
                        .padding(.horizontal, BobaSpacing.sm)
                        .padding(.vertical, BobaSpacing.xs)
                        .background(
                            viewModel?.selectedCategory?.id == category.id
                                ? Color(hex: category.colorHex)
                                : BobaColors.surfaceSecondary
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, BobaSpacing.md)
        }
    }

    // MARK: - Account Selector

    private var accountSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BobaSpacing.xs) {
                ForEach(viewModel?.accounts ?? [], id: \.id) { account in
                    Button {
                        viewModel?.selectedAccount = account
                        viewModel?.currencyCode = account.currencyCode
                        BobaHaptics.selection()
                    } label: {
                        HStack(spacing: BobaSpacing.xxs) {
                            Image(systemName: account.icon)
                                .font(.system(size: 12))
                            Text(account.name)
                                .font(BobaFont.bodySmall())
                        }
                        .foregroundStyle(
                            viewModel?.selectedAccount?.id == account.id
                                ? BobaColors.textOnAccent
                                : BobaColors.textSecondary
                        )
                        .padding(.horizontal, BobaSpacing.sm)
                        .padding(.vertical, BobaSpacing.xs)
                        .background(
                            viewModel?.selectedAccount?.id == account.id
                                ? BobaColors.deepWalnut
                                : BobaColors.surfaceSecondary
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, BobaSpacing.md)
        }
    }

    // MARK: - Note Field

    private var noteField: some View {
        HStack {
            Image(systemName: "note.text")
                .foregroundStyle(BobaColors.textTertiary)
                .font(.system(size: 14))

            TextField("Add a note...", text: Binding(
                get: { viewModel?.note ?? "" },
                set: { viewModel?.note = $0 }
            ))
            .font(BobaFont.bodyMedium())
            .foregroundStyle(BobaColors.textPrimary)
            .tint(BobaColors.fieryTerracotta)
        }
        .padding(BobaSpacing.sm)
        .background(BobaColors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
    }

    // MARK: - Numpad

    private var numpad: some View {
        let buttons = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            [".", "0", "⌫"]
        ]

        return VStack(spacing: BobaSpacing.xs) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: BobaSpacing.xs) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            if key == "⌫" {
                                viewModel?.deleteLastDigit()
                            } else {
                                viewModel?.appendDigit(key)
                            }
                        } label: {
                            Text(key)
                                .font(BobaFont.displaySmall())
                                .foregroundStyle(BobaColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(BobaColors.surfacePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            if viewModel?.save() == true {
                onSave?()
                dismiss()
            }
        } label: {
            Text("Save Transaction")
                .font(BobaFont.headlineMedium())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    viewModel?.isValid == true
                        ? BobaColors.fieryTerracotta
                        : BobaColors.surfaceSecondary
                )
                .clipShape(RoundedRectangle(cornerRadius: BobaRadius.lg))
        }
        .disabled(viewModel?.isValid != true)
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: [Transaction.self, Category.self, Account.self], inMemory: true)
}
