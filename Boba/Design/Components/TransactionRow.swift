import SwiftUI

/// A single transaction row for lists.
struct TransactionRow: View {
    let transaction: Transaction
    let currencyCode: String

    private var typeColor: Color {
        switch transaction.type {
        case .income: return BobaColors.limeCream
        case .expense: return BobaColors.fieryTerracotta
        case .transfer: return BobaColors.metallicGold
        }
    }

    private var amountText: String {
        CurrencyService.shared.formatSigned(
            transaction.amount,
            currencyCode: transaction.currencyCode,
            type: transaction.type
        )
    }

    var body: some View {
        HStack(spacing: BobaSpacing.sm) {
            // Category icon
            categoryIcon

            // Name & details
            VStack(alignment: .leading, spacing: BobaSpacing.xxxs) {
                Text(transaction.category?.name ?? transaction.type.displayName)
                    .font(BobaFont.headlineSmall())
                    .foregroundStyle(BobaColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: BobaSpacing.xxs) {
                    if !transaction.note.isEmpty {
                        Text(transaction.note)
                            .font(BobaFont.bodySmall())
                            .foregroundStyle(BobaColors.textTertiary)
                            .lineLimit(1)
                    }

                    if transaction.isRecurring {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10))
                            .foregroundStyle(BobaColors.textTertiary)
                    }
                }
            }

            Spacer()

            // Amount
            Text(amountText)
                .font(BobaFont.amountSmall())
                .foregroundStyle(typeColor)
        }
        .padding(.vertical, BobaSpacing.xs)
        .contentShape(Rectangle())
    }

    private var categoryIcon: some View {
        let iconName = transaction.category?.icon ?? transaction.type.icon
        let colorHex = transaction.category?.colorHex ?? "d1603d"

        return Image(systemName: iconName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color(hex: colorHex))
            .frame(width: 40, height: 40)
            .background(Color(hex: colorHex).opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
    }
}

// MARK: - Day Section Header

struct TransactionDayHeader: View {
    let date: Date
    let total: String

    var body: some View {
        HStack {
            Text(date.relativeDayString)
                .font(BobaFont.label())
                .foregroundStyle(BobaColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.8)

            Spacer()

            Text(total)
                .font(BobaFont.amountTiny())
                .foregroundStyle(BobaColors.textSecondary)
        }
        .padding(.horizontal, BobaSpacing.md)
        .padding(.vertical, BobaSpacing.xs)
    }
}
