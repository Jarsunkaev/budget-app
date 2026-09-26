import SwiftUI
import SwiftData

/// Staggered paycheck pocket planner.
/// Precalculates how to allocate partial / staggered household income across envelopes,
/// showing exact transfer amounts for banking app pockets today and remaining balances for the next paycheck.
struct PocketAllocationPlannerSheet: View {
    @Environment(\.dismiss) private var dismiss

    enum AllocationStrategy: String, CaseIterable, Identifiable {
        case needsFirst = "Needs First"
        case proportional = "Split %"
        case custom = "Custom"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .needsFirst: return "shield.checkered"
            case .proportional: return "percent"
            case .custom: return "slider.horizontal.3"
            }
        }

        var description: String {
            switch self {
            case .needsFirst:
                return "Prioritizes fixed essentials (Rent, Groceries, Utilities) before discretionary pockets."
            case .proportional:
                return "Distributes income proportionally across all envelopes based on available funds."
            case .custom:
                return "Manually adjust pocket allocations according to your needs."
            }
        }
    }

    struct PocketItem: Identifiable {
        let id: UUID
        let name: String
        let icon: String
        let colorHex: String
        let isNeed: Bool
        let targetLimit: Decimal
        var allocatedNow: Decimal
        var remainingForNextPaycheck: Decimal {
            max(Decimal.zero, targetLimit - allocatedNow)
        }
        var isFullyFunded: Bool {
            allocatedNow >= targetLimit
        }
    }

    var budgets: [Budget]
    var initialIncome: Decimal
    var currencyCode: String

    @State private var incomeString: String = ""
    @State private var strategy: AllocationStrategy = .needsFirst
    @State private var pocketItems: [PocketItem] = []
    @State private var copiedChecklist = false
    @State private var editingPocketId: UUID? = nil
    @State private var customAllocations: [UUID: Decimal] = [:]

    init(budgets: [Budget], initialIncome: Decimal = 0, currencyCode: String = "EUR") {
        self.budgets = budgets
        self.initialIncome = initialIncome
        self.currencyCode = currencyCode
    }

    private var currentIncome: Decimal {
        Decimal(string: incomeString) ?? initialIncome
    }

    private var totalTargetLimit: Decimal {
        budgets.reduce(Decimal.zero) { $0 + $1.limitAmount }
    }

    private var totalAllocatedNow: Decimal {
        pocketItems.reduce(Decimal.zero) { $0 + $1.allocatedNow }
    }

    private var totalRemainingForNextPaycheck: Decimal {
        pocketItems.reduce(Decimal.zero) { $0 + $1.remainingForNextPaycheck }
    }

    private var unallocatedIncome: Decimal {
        max(Decimal.zero, currentIncome - totalAllocatedNow)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BobaColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: BobaSpacing.lg) {
                        // Explanation & Tip Banner
                        infoBanner

                        // Income input hero
                        incomeInputCard

                        // Strategy Selector
                        strategyPicker

                        // Allocation progress overview
                        allocationOverviewCard

                        // Envelopes / Pockets list
                        pocketsListSection

                        // Action Buttons (Copy checklist & Done)
                        actionButtons
                    }
                    .padding(.horizontal, BobaSpacing.md)
                    .padding(.vertical, BobaSpacing.lg)
                }
            }
            .navigationTitle("Pocket Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(BobaColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        copyChecklistToClipboard()
                    } label: {
                        HStack(spacing: BobaSpacing.xxs) {
                            Image(systemName: copiedChecklist ? "checkmark.circle.fill" : "doc.on.doc")
                            Text(copiedChecklist ? "Copied" : "Copy")
                        }
                        .font(BobaFont.bodyMedium().bold())
                        .foregroundStyle(copiedChecklist ? BobaColors.limeCream : BobaColors.textPrimary)
                    }
                }
            }
            .onAppear {
                let initVal = initialIncome > 0 ? initialIncome : totalTargetLimit * Decimal(0.5)
                let decimalNum = NSDecimalNumber(decimal: initVal)
                if decimalNum.doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
                    incomeString = "\(decimalNum.int64Value)"
                } else {
                    incomeString = decimalNum.stringValue
                }
                recalculateAllocations()
            }
            .onChange(of: strategy) { _, _ in
                recalculateAllocations()
            }
        }
    }

    // MARK: - Info Banner

    private var infoBanner: some View {
        HStack(alignment: .top, spacing: BobaSpacing.sm) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(BobaColors.limeCream)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Staggered Household Paychecks")
                    .font(BobaFont.headlineSmall())
                    .foregroundStyle(BobaColors.textPrimary)

                Text("Allocate your incoming paycheck today across banking app pockets. Boba tracks what is funded now and highlights the remainder to fill when the 2nd paycheck arrives.")
                    .font(BobaFont.caption())
                    .foregroundStyle(BobaColors.textSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(BobaSpacing.md)
        .background(BobaColors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
    }

    // MARK: - Income Input Card

    private var incomeInputCard: some View {
        BobaCard {
            VStack(alignment: .leading, spacing: BobaSpacing.xs) {
                Text("INCOMING PAYCHECK TO ALLOCATE")
                    .font(BobaFont.overline())
                    .foregroundStyle(BobaColors.textTertiary)
                    .tracking(1)

                HStack(alignment: .firstTextBaseline, spacing: BobaSpacing.xs) {
                    Text(CurrencyService.shared.symbol(for: currencyCode))
                        .font(BobaFont.displaySmall())
                        .foregroundStyle(BobaColors.textSecondary)

                    TextField("Amount", text: $incomeString)
                        .keyboardType(.decimalPad)
                        .font(BobaFont.displayLarge())
                        .foregroundStyle(BobaColors.limeCream)
                        .onChange(of: incomeString) { _, _ in
                            recalculateAllocations()
                        }
                }

                if unallocatedIncome > 0 {
                    Text("\(CurrencyService.shared.format(unallocatedIncome, currencyCode: currencyCode)) unassigned buffer remains")
                        .font(BobaFont.caption())
                        .foregroundStyle(BobaColors.metallicGold)
                }
            }
        }
    }

    // MARK: - Strategy Picker

    private var strategyPicker: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.xs) {
            Text("ALLOCATION STRATEGY")
                .font(BobaFont.overline())
                .foregroundStyle(BobaColors.textTertiary)
                .tracking(1)

            HStack(spacing: BobaSpacing.xs) {
                ForEach(AllocationStrategy.allCases) { item in
                    Button {
                        withAnimation(BobaAnimation.quick) {
                            strategy = item
                        }
                        BobaHaptics.selection()
                    } label: {
                        HStack(spacing: BobaSpacing.xxs) {
                            Image(systemName: item.icon)
                                .font(.system(size: 11))
                            Text(item.rawValue)
                                .font(BobaFont.bodySmall().bold())
                        }
                        .foregroundStyle(strategy == item ? BobaColors.shadowGrey : BobaColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BobaSpacing.sm)
                        .background(strategy == item ? BobaColors.limeCream : BobaColors.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.sm))
                    }
                    .buttonStyle(BobaPressableButtonStyle())
                }
            }

            Text(strategy.description)
                .font(BobaFont.caption())
                .foregroundStyle(BobaColors.textTertiary)
                .padding(.top, 2)
        }
    }

    // MARK: - Allocation Overview Card

    private var allocationOverviewCard: some View {
        BobaCard {
            HStack(spacing: BobaSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TRANSFER NOW")
                        .font(BobaFont.overline())
                        .foregroundStyle(BobaColors.textTertiary)
                        .tracking(1)

                    Text(CurrencyService.shared.format(totalAllocatedNow, currencyCode: currencyCode))
                        .font(BobaFont.headlineLarge())
                        .foregroundStyle(BobaColors.limeCream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("to banking app pockets")
                        .font(BobaFont.caption())
                        .foregroundStyle(BobaColors.textSecondary)
                }

                Spacer()

                Rectangle()
                    .fill(BobaColors.surfaceSecondary)
                    .frame(width: 1, height: 44)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("REMAINDER")
                        .font(BobaFont.overline())
                        .foregroundStyle(BobaColors.textTertiary)
                        .tracking(1)

                    Text(CurrencyService.shared.format(totalRemainingForNextPaycheck, currencyCode: currencyCode))
                        .font(BobaFont.headlineLarge())
                        .foregroundStyle(totalRemainingForNextPaycheck > 0 ? BobaColors.metallicGold : BobaColors.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("due on 2nd paycheck")
                        .font(BobaFont.caption())
                        .foregroundStyle(BobaColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Pockets List

    private var pocketsListSection: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.sm) {
            Text("POCKET ALLOCATIONS")
                .font(BobaFont.overline())
                .foregroundStyle(BobaColors.textTertiary)
                .tracking(1)

            ForEach(pocketItems) { item in
                pocketRow(item)
            }
        }
    }

    private func pocketRow(_ item: PocketItem) -> some View {
        VStack(spacing: BobaSpacing.xs) {
            HStack(spacing: BobaSpacing.sm) {
                // Category icon squircle
                ZStack {
                    RoundedRectangle(cornerRadius: BobaRadius.sm)
                        .fill(Color(hex: item.colorHex).opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: item.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: item.colorHex))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: BobaSpacing.xxs) {
                        Text(item.name)
                            .font(BobaFont.bodyMedium().bold())
                            .foregroundStyle(BobaColors.textPrimary)

                        if item.isNeed {
                            Text("NEED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(BobaColors.fieryTerracotta)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(BobaColors.fieryTerracotta.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }

                    Text("Target: \(CurrencyService.shared.format(item.targetLimit, currencyCode: currencyCode))")
                        .font(BobaFont.caption())
                        .foregroundStyle(BobaColors.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(CurrencyService.shared.format(item.allocatedNow, currencyCode: currencyCode))
                            .font(BobaFont.headlineSmall())
                            .foregroundStyle(item.allocatedNow > 0 ? BobaColors.limeCream : BobaColors.textTertiary)

                        if item.isFullyFunded {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(BobaColors.limeCream)
                        }
                    }

                    if item.remainingForNextPaycheck > 0 {
                        Text("+\(CurrencyService.shared.format(item.remainingForNextPaycheck, currencyCode: currencyCode)) on 2nd")
                            .font(BobaFont.caption())
                            .foregroundStyle(BobaColors.metallicGold)
                    } else {
                        Text("100% Funded")
                            .font(BobaFont.caption())
                            .foregroundStyle(BobaColors.limeCream.opacity(0.8))
                    }
                }
            }

            // Dual-stage progress bar: Solid = Funded Now, Amber = Remainder on 2nd Paycheck
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let target = NSDecimalNumber(decimal: item.targetLimit).doubleValue
                let now = NSDecimalNumber(decimal: item.allocatedNow).doubleValue
                let fundedRatio = target > 0 ? min(1.0, max(0.0, now / target)) : 0.0

                ZStack(alignment: .leading) {
                    // Background track (Target)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(BobaColors.surfaceSecondary)
                        .frame(height: 6)

                    // Target remainder placeholder (Subtle amber)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(BobaColors.metallicGold.opacity(0.35))
                        .frame(width: totalWidth, height: 6)

                    // Funded now solid fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: item.colorHex))
                        .frame(width: totalWidth * CGFloat(fundedRatio), height: 6)
                }
            }
            .frame(height: 6)
            .padding(.top, 2)
        }
        .padding(BobaSpacing.md)
        .background(BobaColors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: BobaSpacing.sm) {
            Button {
                copyChecklistToClipboard()
            } label: {
                HStack(spacing: BobaSpacing.xs) {
                    Image(systemName: copiedChecklist ? "checkmark" : "doc.on.doc.fill")
                        .font(.system(size: 15, weight: .bold))

                    Text(copiedChecklist ? "Checklist Copied to Clipboard!" : "Copy Pocket Transfer Checklist")
                        .font(BobaFont.headlineSmall())
                }
                .foregroundStyle(BobaColors.shadowGrey)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(BobaColors.limeCream)
                .clipShape(RoundedRectangle(cornerRadius: BobaRadius.lg))
            }
            .buttonStyle(BobaPressableButtonStyle())

            Text("Copy this list to effortlessly execute pocket transfers inside your financial or banking app.")
                .font(BobaFont.caption())
                .foregroundStyle(BobaColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BobaSpacing.md)
        }
        .padding(.top, BobaSpacing.xs)
    }

    // MARK: - Calculation Engine

    private func recalculateAllocations() {
        let income = currentIncome
        guard income > 0, !budgets.isEmpty else {
            pocketItems = budgets.map { b in
                PocketItem(
                    id: b.id,
                    name: b.category?.name ?? "Envelope",
                    icon: b.category?.icon ?? "tray.fill",
                    colorHex: b.category?.colorHex ?? "d1603d",
                    isNeed: b.category?.type == .need,
                    targetLimit: b.limitAmount,
                    allocatedNow: 0
                )
            }
            return
        }

        switch strategy {
        case .needsFirst:
            // 1. Sort: Needs first, then wants (both in descending target size)
            let sortedBudgets = budgets.sorted { b1, b2 in
                let n1 = b1.category?.type == .need
                let n2 = b2.category?.type == .need
                if n1 != n2 { return n1 && !n2 }
                return b1.limitAmount > b2.limitAmount
            }

            var remainingIncome = income
            var itemsMap: [UUID: Decimal] = [:]

            for b in sortedBudgets {
                let toAllocate = min(remainingIncome, b.limitAmount)
                itemsMap[b.id] = toAllocate
                remainingIncome = max(Decimal.zero, remainingIncome - toAllocate)
            }

            pocketItems = budgets.map { b in
                PocketItem(
                    id: b.id,
                    name: b.category?.name ?? "Envelope",
                    icon: b.category?.icon ?? "tray.fill",
                    colorHex: b.category?.colorHex ?? "d1603d",
                    isNeed: b.category?.type == .need,
                    targetLimit: b.limitAmount,
                    allocatedNow: itemsMap[b.id] ?? Decimal.zero
                )
            }

        case .proportional:
            let total = totalTargetLimit
            guard total > 0 else { return }

            let incomeNum = NSDecimalNumber(decimal: income).doubleValue
            let totalNum = NSDecimalNumber(decimal: total).doubleValue
            let ratio = min(1.0, max(0.0, incomeNum / totalNum))

            pocketItems = budgets.map { b in
                let limitDouble = NSDecimalNumber(decimal: b.limitAmount).doubleValue
                let allocatedDouble = (limitDouble * ratio).rounded()
                let allocated = min(b.limitAmount, Decimal(allocatedDouble))
                return PocketItem(
                    id: b.id,
                    name: b.category?.name ?? "Envelope",
                    icon: b.category?.icon ?? "tray.fill",
                    colorHex: b.category?.colorHex ?? "d1603d",
                    isNeed: b.category?.type == .need,
                    targetLimit: b.limitAmount,
                    allocatedNow: allocated
                )
            }

        case .custom:
            pocketItems = budgets.map { b in
                PocketItem(
                    id: b.id,
                    name: b.category?.name ?? "Envelope",
                    icon: b.category?.icon ?? "tray.fill",
                    colorHex: b.category?.colorHex ?? "d1603d",
                    isNeed: b.category?.type == .need,
                    targetLimit: b.limitAmount,
                    allocatedNow: customAllocations[b.id] ?? Decimal.zero
                )
            }
        }
    }

    // MARK: - Clipboard Copy

    private func copyChecklistToClipboard() {
        var lines: [String] = []
        lines.append("📋 Pocket Transfer Checklist (\(strategy.rawValue))")
        lines.append("Incoming Income: \(CurrencyService.shared.format(currentIncome, currencyCode: currencyCode))")
        lines.append("────────────────────────")

        for item in pocketItems {
            let status = item.isFullyFunded
                ? "✓ Full"
                : "(+\(CurrencyService.shared.format(item.remainingForNextPaycheck, currencyCode: currencyCode)) on 2nd paycheck)"
            lines.append("• \(item.name) Pocket: \(CurrencyService.shared.format(item.allocatedNow, currencyCode: currencyCode)) \(status)")
        }

        lines.append("────────────────────────")
        lines.append("Total to Transfer Now: \(CurrencyService.shared.format(totalAllocatedNow, currencyCode: currencyCode))")
        if totalRemainingForNextPaycheck > 0 {
            lines.append("Total Remainder for 2nd Paycheck: \(CurrencyService.shared.format(totalRemainingForNextPaycheck, currencyCode: currencyCode))")
        }

        let fullText = lines.joined(separator: "\n")
        UIPasteboard.general.string = fullText

        BobaHaptics.success()
        withAnimation(BobaAnimation.quick) {
            copiedChecklist = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(BobaAnimation.quick) {
                copiedChecklist = false
            }
        }
    }
}
