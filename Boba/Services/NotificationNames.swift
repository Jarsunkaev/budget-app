import Foundation

extension Notification.Name {
    /// Broadcast when transactions, budgets, or categories are created, updated, or deleted.
    static let bobaDataDidChange = Notification.Name("bobaDataDidChange")

    /// Broadcast to switch tab to the Budgets screen.
    static let bobaNavigateToBudgets = Notification.Name("bobaNavigateToBudgets")

    /// Broadcast to pop back to the Dashboard root view when Home tab is tapped.
    static let bobaResetHomeNavigation = Notification.Name("bobaResetHomeNavigation")
}
