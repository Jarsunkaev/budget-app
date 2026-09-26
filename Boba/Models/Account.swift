import Foundation
import SwiftData

/// A financial account (checking, savings, credit card, cash, etc.).
@Model
final class Account {
    var id: UUID
    var name: String
    var type: AccountType
    var initialBalance: Decimal
    var currencyCode: String
    var icon: String
    var colorHex: String
    var isActive: Bool
    var sortOrder: Int
    var createdAt: Date

    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Transaction.account)
    var transactions: [Transaction]

    init(
        id: UUID = UUID(),
        name: String,
        type: AccountType = .checking,
        initialBalance: Decimal = 0,
        currencyCode: String = "EUR",
        icon: String? = nil,
        colorHex: String = "d1603d",
        isActive: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.initialBalance = initialBalance
        self.currencyCode = currencyCode
        self.icon = icon ?? type.icon
        self.colorHex = colorHex
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.transactions = []
        self.createdAt = .now
    }

    /// Current balance computed from initial balance and all transactions.
    var currentBalance: Decimal {
        let transactionTotal = transactions.reduce(Decimal.zero) { total, tx in
            total + tx.signedAmount
        }
        return initialBalance + transactionTotal
    }
}
