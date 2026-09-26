import SwiftUI

// MARK: - Haptic Feedback

enum BobaHaptics {
    /// Light tap — used for selections, toggles.
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium tap — used for adding transactions, confirming actions.
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Heavy tap — used for deleting, important warnings.
    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    /// Success — used for completing a goal, staying under budget.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Warning — used for approaching budget limits.
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Error — used for over-budget, failed operations.
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// Selection changed — used for picker changes, tab switches.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
