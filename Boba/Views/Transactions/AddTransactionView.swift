import SwiftUI
import SwiftData

/// Quick add transaction screen with numpad-first design and Smart Log voice/text parsing.
/// Designed for under 5 seconds manual or hands-free logging.
struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddTransactionViewModel?
    @State private var showSmartLogSheet = false
    @State private var voiceInputText = ""
    @State private var selectedType: TransactionType
    @FocusState private var isNoteFocused: Bool

    var initialType: TransactionType = .expense
    var onSave: (() -> Void)? = nil

    init(initialType: TransactionType = .expense, onSave: (() -> Void)? = nil) {
        self.initialType = initialType
        self.onSave = onSave
        self._selectedType = State(initialValue: initialType)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BobaColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Smart Log Search Bar (Tapping raises full modal)
                    smartLogHeader
                        .padding(.top, BobaSpacing.xs)

                    // Type selector (Income, Expense, Transfer)
                    typeSelector
                        .padding(.top, BobaSpacing.xs)

                    Spacer(minLength: BobaSpacing.xxs)

                    // Centered Amount display container
                    amountDisplay
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BobaSpacing.xs)

                    Spacer(minLength: BobaSpacing.xxs)

                    // Feedback Pill if Smart Log parsed
                    if let feedback = viewModel?.voiceFeedbackMessage {
                        HStack(spacing: BobaSpacing.xxs) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundStyle(BobaColors.limeCream)

                            Text(feedback)
                                .font(BobaFont.caption().bold())
                                .foregroundStyle(BobaColors.textPrimary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, BobaSpacing.sm)
                        .padding(.vertical, 6)
                        .background(BobaColors.surfaceElevated.opacity(0.8))
                        .clipShape(Capsule())
                        .transition(.scale.combined(with: .opacity))
                        .padding(.bottom, BobaSpacing.xs)
                    }

                    // Category picker
                    categoryPicker
                        .padding(.bottom, BobaSpacing.xs)

                    // Account selector
                    accountSelector
                        .padding(.bottom, BobaSpacing.xs)

                    // Note field
                    noteField
                        .padding(.horizontal, BobaSpacing.md)
                        .padding(.bottom, BobaSpacing.xs)

                    // Numpad (Hidden when editing note text to prevent modal jumbling)
                    if !isNoteFocused {
                        numpad
                            .padding(.horizontal, BobaSpacing.md)
                            .padding(.bottom, BobaSpacing.xs)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Save button
                    saveButton
                        .padding(.horizontal, BobaSpacing.md)
                        .padding(.bottom, BobaSpacing.md)
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
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isNoteFocused = false
                        }
                        .font(BobaFont.bodyMedium().bold())
                        .foregroundStyle(BobaColors.limeCream)
                    }
                }
            }
            .onAppear {
                if viewModel == nil {
                    let vm = AddTransactionViewModel(modelContext: modelContext, initialType: selectedType)
                    viewModel = vm
                } else {
                    viewModel?.type = selectedType
                }
                viewModel?.loadData()
            }
            .onChange(of: initialType) { _, newType in
                selectedType = newType
                viewModel?.type = newType
            }
            .sheet(isPresented: $showSmartLogSheet, onDismiss: {
                viewModel?.stopVoiceListening()
            }) {
                smartLogSheetView
            }
        }
    }

    // MARK: - Smart Log Search Bar Header (Tapping opens sheet)

    private var smartLogHeader: some View {
        Button {
            showSmartLogSheet = true
            BobaHaptics.selection()
        } label: {
            HStack(spacing: BobaSpacing.xs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BobaColors.limeCream)

                Text("Smart Log: \"Transferred 320k HUF for Rent\"")
                    .font(BobaFont.caption())
                    .foregroundStyle(BobaColors.textSecondary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(BobaColors.limeCream)
            }
            .padding(.horizontal, BobaSpacing.md)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(BobaColors.surfaceElevated.opacity(0.6))
            .clipShape(Capsule())
        }
        .buttonStyle(BobaPressableButtonStyle())
        .padding(.horizontal, BobaSpacing.md)
    }

    // MARK: - Type Selector (Order: Income -> Expense -> Transfer)

    private var typeSelector: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases) { type in
                let isSelected = selectedType == type
                Button {
                    withAnimation(BobaAnimation.quick) {
                        selectedType = type
                        viewModel?.type = type
                    }
                    BobaHaptics.selection()
                } label: {
                    Text(type.displayName)
                        .font(BobaFont.headlineSmall())
                        .foregroundStyle(isSelected ? BobaColors.textOnAccent : BobaColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BobaSpacing.xs)
                        .background(
                            isSelected
                                ? (type == .income ? BobaColors.limeCream.opacity(0.85) :
                                   type == .transfer ? BobaColors.metallicGold.opacity(0.85) : BobaColors.fieryTerracotta)
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity)
        .background(BobaColors.surfacePrimary)
        .clipShape(Capsule())
        .padding(.horizontal, BobaSpacing.md)
    }

    // MARK: - Amount Display

    private var amountDisplay: some View {
        let amountText = (viewModel?.amountString.isEmpty == false) ? viewModel!.amountString : "0"
        let isEmpty = viewModel?.amountString.isEmpty != false

        return VStack(spacing: BobaSpacing.xxs) {
            HStack(alignment: .center, spacing: BobaSpacing.xs) {
                Text(CurrencyService.shared.symbol(for: viewModel?.currencyCode ?? "EUR"))
                    .font(BobaFont.displaySmall())
                    .foregroundStyle(BobaColors.textSecondary)

                Text(amountText)
                    .font(BobaFont.displayLarge())
                    .foregroundStyle(isEmpty ? BobaColors.textTertiary : BobaColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, BobaSpacing.md)
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

    @ViewBuilder
    private var accountSelector: some View {
        if (viewModel?.accounts.count ?? 0) > 1 {
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
                                    ? BobaColors.fieryTerracotta
                                    : BobaColors.surfaceSecondary
                            )
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, BobaSpacing.md)
            }
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
            .focused($isNoteFocused)
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
            [".", "0", "\u{232B}"]
        ]

        return VStack(spacing: BobaSpacing.xs) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: BobaSpacing.xs) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            if key == "\u{232B}" {
                                viewModel?.deleteLastDigit()
                            } else {
                                viewModel?.appendDigit(key)
                            }
                        } label: {
                            Text(key)
                                .font(BobaFont.displaySmall())
                                .foregroundStyle(BobaColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
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
                .frame(height: 48)
                .background(
                    viewModel?.isValid == true
                        ? BobaColors.fieryTerracotta
                        : BobaColors.surfaceSecondary
                )
                .clipShape(RoundedRectangle(cornerRadius: BobaRadius.lg))
        }
        .disabled(viewModel?.isValid != true)
    }

    // MARK: - Smart Log Full Modal Sheet View

    private var smartLogSheetView: some View {
        ZStack {
            BobaColors.background.ignoresSafeArea()

            VStack(spacing: BobaSpacing.lg) {
                // Drag handle & top bar
                HStack {
                    Spacer()
                    Button("Done") {
                        if !voiceInputText.isEmpty {
                            viewModel?.processVoiceText(voiceInputText)
                        }
                        viewModel?.stopVoiceListening()
                        showSmartLogSheet = false
                    }
                    .font(BobaFont.bodyMedium().bold())
                    .foregroundStyle(BobaColors.limeCream)
                    .padding(.trailing, BobaSpacing.md)
                    .padding(.top, BobaSpacing.md)
                }

                // Header Mic Visualizer (Clean dark theme glass ring, no red glow)
                VStack(spacing: BobaSpacing.md) {
                    Button {
                        viewModel?.toggleVoiceListening(onTranscriptUpdated: { text in
                            voiceInputText = text
                        })
                    } label: {
                        ZStack {
                            Circle()
                                .fill(BobaColors.surfaceElevated.opacity(0.8))
                                .frame(width: 84, height: 84)

                            Circle()
                                .stroke(viewModel?.isVoiceListening == true ? BobaColors.fieryTerracotta : BobaColors.limeCream.opacity(0.4), lineWidth: 2)
                                .frame(width: 96, height: 96)

                            Image(systemName: viewModel?.isVoiceListening == true ? "waveform" : "mic.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(viewModel?.isVoiceListening == true ? BobaColors.fieryTerracotta : BobaColors.limeCream)
                        }
                    }
                    .buttonStyle(BobaPressableButtonStyle())

                    Text(viewModel?.isVoiceListening == true ? "Listening..." : "Smart Log")
                        .font(BobaFont.displaySmall())
                        .foregroundStyle(BobaColors.textPrimary)

                    Text(viewModel?.voiceFeedbackMessage ?? "Speak into your microphone or type below to automatically autofill entry.")
                        .font(BobaFont.bodySmall())
                        .foregroundStyle(BobaColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BobaSpacing.lg)
                }

                // Text Input / Speech Transcript
                VStack(alignment: .leading, spacing: BobaSpacing.xs) {
                    Text("VOICE TRANSCRIPT OR TYPE")
                        .font(BobaFont.overline())
                        .foregroundStyle(BobaColors.textTertiary)
                        .tracking(1)

                    HStack {
                        TextField("e.g. Transferred 320k HUF for Rent to landlord", text: $voiceInputText)
                            .font(BobaFont.bodyLarge())
                            .foregroundStyle(BobaColors.textPrimary)
                            .onChange(of: voiceInputText) { _, newText in
                                if !newText.isEmpty {
                                    viewModel?.processVoiceText(newText)
                                }
                            }

                        if !voiceInputText.isEmpty {
                            Button {
                                voiceInputText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(BobaColors.textTertiary)
                            }
                        }
                    }
                    .padding(BobaSpacing.md)
                    .background(BobaColors.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                }
                .padding(.horizontal, BobaSpacing.md)

                // Quick Sample Prompts
                VStack(alignment: .leading, spacing: BobaSpacing.xs) {
                    Text("SAMPLE PHRASES")
                        .font(BobaFont.overline())
                        .foregroundStyle(BobaColors.textTertiary)
                        .tracking(1)
                        .padding(.horizontal, BobaSpacing.md)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: BobaSpacing.xs) {
                            samplePill("Transferred 320k HUF for Rent to landlord")
                            samplePill("Spent 15.5 EUR on coffee at Starbucks")
                            samplePill("Received 850k HUF salary income")
                            samplePill("Paid 45k HUF for groceries at Lidl")
                        }
                        .padding(.horizontal, BobaSpacing.md)
                    }
                }

                Spacer()

                // Parse & Apply Button
                Button {
                    if !voiceInputText.isEmpty {
                        viewModel?.processVoiceText(voiceInputText)
                        BobaHaptics.success()
                        viewModel?.stopVoiceListening()
                        showSmartLogSheet = false
                    }
                } label: {
                    HStack(spacing: BobaSpacing.xs) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                        Text("Parse & Autofill Entry")
                            .font(BobaFont.headlineMedium())
                    }
                    .foregroundStyle(BobaColors.shadowGrey)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        voiceInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? BobaColors.surfaceSecondary
                            : BobaColors.limeCream
                    )
                    .clipShape(RoundedRectangle(cornerRadius: BobaRadius.lg))
                }
                .disabled(voiceInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, BobaSpacing.md)
                .padding(.bottom, BobaSpacing.md)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            viewModel?.startVoiceListening(onTranscriptUpdated: { text in
                voiceInputText = text
            })
        }
    }

    private func samplePill(_ text: String) -> some View {
        Button {
            voiceInputText = text
            viewModel?.processVoiceText(text)
            BobaHaptics.selection()
        } label: {
            Text("\"\(text)\"")
                .font(BobaFont.caption())
                .foregroundStyle(BobaColors.textSecondary)
                .padding(.horizontal, BobaSpacing.sm)
                .padding(.vertical, BobaSpacing.xs)
                .background(BobaColors.surfaceSecondary)
                .clipShape(Capsule())
        }
    }
}
