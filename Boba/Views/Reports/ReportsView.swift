import SwiftUI
import SwiftData
import Charts

/// Reports tab with spending analysis charts.
struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ReportsViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BobaSpacing.xl) {
                    // Period selector
                    periodSelector

                    // Income vs Expenses summary
                    summaryCard

                    // Category breakdown chart
                    categoryChart

                    // Spending trend chart
                    trendChart

                    // Monthly comparison
                    monthlyChart
                }
                .padding(.horizontal, BobaSpacing.md)
                .padding(.bottom, BobaSpacing.xxxl)
            }
            .background(BobaColors.background)
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if viewModel == nil {
                    viewModel = ReportsViewModel(modelContext: modelContext)
                }
                viewModel?.refresh()
            }
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BobaSpacing.xs) {
                ForEach(ReportsViewModel.ReportPeriod.allCases) { period in
                    Button {
                        withAnimation(BobaAnimation.quick) {
                            viewModel?.selectedPeriod = period
                        }
                        BobaHaptics.selection()
                    } label: {
                        Text(period.rawValue)
                            .font(BobaFont.bodySmall())
                            .foregroundStyle(
                                viewModel?.selectedPeriod == period
                                    ? BobaColors.textOnAccent
                                    : BobaColors.textSecondary
                            )
                            .padding(.horizontal, BobaSpacing.md)
                            .padding(.vertical, BobaSpacing.xs)
                            .background(
                                viewModel?.selectedPeriod == period
                                    ? BobaColors.fieryTerracotta
                                    : BobaColors.surfacePrimary
                            )
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        BobaCard {
            HStack(spacing: BobaSpacing.xl) {
                VStack(alignment: .leading, spacing: BobaSpacing.xxs) {
                    Text("INCOME")
                        .font(BobaFont.overline())
                        .foregroundStyle(BobaColors.textTertiary)
                        .tracking(1)
                    Text(viewModel?.formattedIncome ?? "€0")
                        .font(BobaFont.amountMedium())
                        .foregroundStyle(BobaColors.limeCream)
                }

                VStack(alignment: .leading, spacing: BobaSpacing.xxs) {
                    Text("EXPENSES")
                        .font(BobaFont.overline())
                        .foregroundStyle(BobaColors.textTertiary)
                        .tracking(1)
                    Text(viewModel?.formattedExpenses ?? "€0")
                        .font(BobaFont.amountMedium())
                        .foregroundStyle(BobaColors.fieryTerracotta)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: BobaSpacing.xxs) {
                    Text("NET")
                        .font(BobaFont.overline())
                        .foregroundStyle(BobaColors.textTertiary)
                        .tracking(1)
                    Text(viewModel?.formattedNet ?? "€0")
                        .font(BobaFont.amountMedium())
                        .foregroundStyle(
                            (viewModel?.netAmount ?? 0) >= 0
                                ? BobaColors.limeCream
                                : BobaColors.fieryTerracotta
                        )
                }
            }
        }
    }

    // MARK: - Category Breakdown

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.sm) {
            BobaSectionHeader(title: "By Category")

            BobaCard {
                VStack(spacing: BobaSpacing.md) {
                    if let vm = viewModel, !vm.categoryBreakdown.isEmpty {
                        // Donut chart
                        Chart(vm.categoryBreakdown) { item in
                            SectorMark(
                                angle: .value("Amount", item.amount.doubleValue),
                                innerRadius: .ratio(0.6),
                                angularInset: 2
                            )
                            .foregroundStyle(Color(hex: item.categoryColorHex))
                            .cornerRadius(4)
                        }
                        .frame(height: 200)
                        .chartBackground { _ in
                            VStack {
                                Text(vm.formattedExpenses)
                                    .font(BobaFont.amountSmall())
                                    .foregroundStyle(BobaColors.textPrimary)
                                Text("Total")
                                    .font(BobaFont.caption())
                                    .foregroundStyle(BobaColors.textTertiary)
                            }
                        }

                        // Legend
                        VStack(spacing: BobaSpacing.xs) {
                            ForEach(vm.categoryBreakdown) { item in
                                HStack(spacing: BobaSpacing.xs) {
                                    Circle()
                                        .fill(Color(hex: item.categoryColorHex))
                                        .frame(width: 10, height: 10)

                                    Image(systemName: item.categoryIcon)
                                        .font(.system(size: 12))
                                        .foregroundStyle(BobaColors.textSecondary)

                                    Text(item.categoryName)
                                        .font(BobaFont.bodySmall())
                                        .foregroundStyle(BobaColors.textSecondary)

                                    Spacer()

                                    Text("\(Int(item.percentage * 100))%")
                                        .font(BobaFont.amountTiny())
                                        .foregroundStyle(BobaColors.textTertiary)

                                    Text(vm.formattedAmount(item.amount))
                                        .font(BobaFont.amountTiny())
                                        .foregroundStyle(BobaColors.textPrimary)
                                }
                            }
                        }
                    } else {
                        Text("No data for this period")
                            .font(BobaFont.bodyMedium())
                            .foregroundStyle(BobaColors.textTertiary)
                            .frame(maxWidth: .infinity, minHeight: 100)
                    }
                }
            }
        }
    }

    // MARK: - Spending Trend

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.sm) {
            BobaSectionHeader(title: "Spending Trend")

            BobaCard {
                if let vm = viewModel, !vm.dailySpending.isEmpty {
                    Chart(vm.dailySpending) { item in
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Amount", item.amount.doubleValue)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [BobaColors.fieryTerracotta.opacity(0.4), BobaColors.fieryTerracotta.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Amount", item.amount.doubleValue)
                        )
                        .foregroundStyle(BobaColors.fieryTerracotta)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                .foregroundStyle(BobaColors.textTertiary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                                .foregroundStyle(BobaColors.surfaceSecondary)
                            AxisValueLabel()
                                .foregroundStyle(BobaColors.textTertiary)
                        }
                    }
                } else {
                    Text("No data for this period")
                        .font(BobaFont.bodyMedium())
                        .foregroundStyle(BobaColors.textTertiary)
                        .frame(maxWidth: .infinity, minHeight: 100)
                }
            }
        }
    }

    // MARK: - Monthly Comparison

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.sm) {
            BobaSectionHeader(title: "Monthly Overview")

            BobaCard {
                if let vm = viewModel, !vm.monthlyComparison.isEmpty {
                    Chart(vm.monthlyComparison) { item in
                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Income", item.income.doubleValue)
                        )
                        .foregroundStyle(BobaColors.limeCream.opacity(0.7))
                        .cornerRadius(4)
                        .position(by: .value("Type", "Income"))

                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Expenses", item.expenses.doubleValue)
                        )
                        .foregroundStyle(BobaColors.fieryTerracotta.opacity(0.7))
                        .cornerRadius(4)
                        .position(by: .value("Type", "Expenses"))
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                                .foregroundStyle(BobaColors.textTertiary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                                .foregroundStyle(BobaColors.surfaceSecondary)
                            AxisValueLabel()
                                .foregroundStyle(BobaColors.textTertiary)
                        }
                    }
                    .chartForegroundStyleScale([
                        "Income": BobaColors.limeCream,
                        "Expenses": BobaColors.fieryTerracotta
                    ])
                } else {
                    Text("No data yet")
                        .font(BobaFont.bodyMedium())
                        .foregroundStyle(BobaColors.textTertiary)
                        .frame(maxWidth: .infinity, minHeight: 100)
                }
            }
        }
    }
}
