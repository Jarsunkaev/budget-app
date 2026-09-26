import SwiftUI
import SwiftData

/// Dedicated sheet to view, recategorize, or edit any recent spending / transaction.
struct CategorizeTransactionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]

    let transaction: Transaction
    let currencyCode: String

    @State private var selectedCategory: Category?
    @State private var note: String = ""
    @State private var amountString: String = ""
    @State private var selectedType: TransactionType = .expense
    @State private var showDeleteConfirmation = false
    @State private var savedToast = false

    var onUpdated: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                BobaColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: BobaSpacing.lg) {
                        // Hero Details
                        heroCard

                        // Categorize Section
                        categoryGridSection

                        // Note / Merchant
                        noteSection

                        // Delete
                        deleteSection
                    }
                    .padding(BobaSpacing.md)
                }

                if savedToast {
                    VStack {
                        Spacer()
                        HStack(spacing: BobaSpacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(BobaColors.limeCream)
                            Text("Transaction Updated")
                                .font(BobaFont.headlineSmall())
                                .foregroundStyle(BobaColors.textPrimary)
                        }
                        .padding(.horizontal, BobaSpacing.lg)
                        .padding(.vertical, BobaSpacing.sm)
                        .background(BobaColors.surfaceElevated)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                        .padding(.bottom, BobaSpacing.xl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(10)
                }
            }
            .navigationTitle("Spending Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(BobaColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(BobaFont.headlineSmall())
                    .foregroundStyle(BobaColors.limeCream)
                }
            }
            .onAppear {
                selectedCategory = transaction.category
                note = transaction.note
                amountString = "\(transaction.amount)"
                selectedType = transaction.type
            }
            .alert("Delete Transaction", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(transaction)
                    try? modelContext.save()
                    NotificationCenter.default.post(name: .bobaDataDidChange, object: nil)
                    onUpdated?()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this transaction?")
            }
        }
        .presentationDetents([.large, .fraction(0.85)])
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        BobaCard {
            VStack(spacing: BobaSpacing.sm) {
                HStack {
                    ZStack {
                        Circle()
                            .fill((selectedCategory != nil ? Color(hex: selectedCategory!.colorHex) : BobaColors.fieryTerracotta).opacity(0.18))
                            .frame(width: 56, height: 56)

                        Image(systemName: selectedCategory?.icon ?? transaction.type.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(selectedCategory != nil ? Color(hex: selectedCategory!.colorHex) : BobaColors.fieryTerracotta)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedCategory?.name ?? "Uncategorized")
                            .font(BobaFont.headlineLarge())
                            .foregroundStyle(BobaColors.textPrimary)

                        Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                            .font(BobaFont.bodySmall())
                            .foregroundStyle(BobaColors.textTertiary)
                    }

                    Spacer()

                    Text(CurrencyService.shared.formatSigned(transaction.amount, currencyCode: currencyCode, type: transaction.type))
                        .font(BobaFont.displaySmall())
                        .foregroundStyle(transaction.type == .income ? BobaColors.limeCream : BobaColors.fieryTerracotta)
                }
            }
        }
    }

    // MARK: - Category Grid Section

    private var categoryGridSection: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.sm) {
            HStack {
                Text("ASSIGN CATEGORY")
                    .font(BobaFont.overline())
                    .foregroundStyle(BobaColors.textTertiary)
                    .tracking(1.0)

                Spacer()

                if let cat = selectedCategory {
                    Text("Selected: \(cat.name)")
                        .font(BobaFont.caption())
                        .foregroundStyle(BobaColors.limeCream)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: BobaSpacing.xs)], spacing: BobaSpacing.xs) {
                ForEach(categories, id: \.id) { category in
                    let isSelected = selectedCategory?.id == category.id
                    Button {
                        withAnimation(BobaAnimation.quick) {
                            selectedCategory = category
                        }
                        BobaHaptics.selection()
                    } label: {
                        HStack(spacing: BobaSpacing.xxs) {
                            Image(systemName: category.icon)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color(hex: category.colorHex))

                            Text(category.name)
                                .font(BobaFont.bodySmall().bold())
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(BobaColors.limeCream)
                            }
                        }
                        .foregroundStyle(isSelected ? BobaColors.textPrimary : BobaColors.textSecondary)
                        .padding(.horizontal, BobaSpacing.sm)
                        .padding(.vertical, BobaSpacing.xs)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(isSelected ? BobaColors.surfaceElevated : BobaColors.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: BobaRadius.md)
                                .stroke(isSelected ? Color(hex: category.colorHex) : BobaColors.surfaceSecondary, lineWidth: isSelected ? 1.5 : 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.xxs) {
            Text("NOTE / MERCHANT")
                .font(BobaFont.overline())
                .foregroundStyle(BobaColors.textTertiary)

            HStack {
                Image(systemName: "square.and.pencil")
                    .foregroundStyle(BobaColors.textTertiary)

                TextField("Add note or merchant name", text: $note)
                    .font(BobaFont.bodyMedium())
                    .foregroundStyle(BobaColors.textPrimary)
            }
            .padding(BobaSpacing.md)
            .background(BobaColors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: BobaRadius.md)
                    .stroke(BobaColors.surfaceSecondary, lineWidth: 1)
            )
        }
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text("Delete Transaction")
            }
            .font(BobaFont.headlineSmall())
            .foregroundStyle(BobaColors.fieryTerracotta)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(BobaColors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        transaction.category = selectedCategory
        transaction.note = note.trimmingCharacters(in: .whitespaces)
        if let dec = Decimal(string: amountString), dec > 0 {
            transaction.amount = dec
        }
        transaction.type = selectedType

        try? modelContext.save()
        NotificationCenter.default.post(name: .bobaDataDidChange, object: nil)
        BobaHaptics.success()
        onUpdated?()

        withAnimation {
            savedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}
