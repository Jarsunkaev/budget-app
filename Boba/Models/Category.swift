import Foundation
import SwiftData

/// A spending category (e.g., Groceries, Dining, Transport).
@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var type: CategoryType
    var sortOrder: Int
    var isDefault: Bool
    var createdAt: Date

    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]

    @Relationship(deleteRule: .nullify, inverse: \Budget.category)
    var budgets: [Budget]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String = "d1603d",
        type: CategoryType = .want,
        sortOrder: Int = 0,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.type = type
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.transactions = []
        self.budgets = []
        self.createdAt = .now
    }

    /// Default categories to seed during onboarding.
    static let defaults: [(name: String, icon: String, color: String, type: CategoryType)] = [
        // Needs
        ("Rent", "house.fill", "d1603d", .need),
        ("Groceries", "cart.fill", "ddb967", .need),
        ("Utilities", "bolt.fill", "ddb967", .need),
        ("Transport", "car.fill", "4f3824", .need),
        ("Insurance", "shield.fill", "4f3824", .need),
        ("Healthcare", "cross.case.fill", "d1603d", .need),

        // Wants
        ("Dining", "fork.knife", "d1603d", .want),
        ("Entertainment", "film.fill", "ddb967", .want),
        ("Shopping", "bag.fill", "d0e37f", .want),
        ("Subscriptions", "arrow.triangle.2.circlepath", "4f3824", .want),
        ("Travel", "airplane", "d1603d", .want),
        ("Coffee", "cup.and.saucer.fill", "ddb967", .want),

        // Savings
        ("Savings", "banknote.fill", "d0e37f", .saving),
        ("Investments", "chart.line.uptrend.xyaxis", "d0e37f", .saving),
        ("Emergency Fund", "lifepreserver.fill", "ddb967", .saving),
    ]
}
