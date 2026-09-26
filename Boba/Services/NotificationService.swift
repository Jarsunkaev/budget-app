import Foundation
import UserNotifications

/// Handles all local notification scheduling for budget alerts,
/// bill reminders, weekly summaries, and goal milestones.
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - Budget Warnings

    func scheduleBudgetWarning(
        categoryName: String,
        percentSpent: Double,
        remaining: String
    ) {
        let content = UNMutableNotificationContent()
        content.sound = .default

        if percentSpent >= 1.0 {
            content.title = "Budget wrapped up 🎯"
            content.body = "Your \(categoryName) budget has been fully used. Let's adjust for the rest of the month?"
        } else if percentSpent >= 0.9 {
            content.title = "Almost there 🔥"
            content.body = "\(categoryName) is at \(Int(percentSpent * 100))%. You have \(remaining) remaining."
        } else if percentSpent >= 0.8 {
            content.title = "Getting warm ☀️"
            content.body = "\(categoryName) budget is at \(Int(percentSpent * 100))%. \(remaining) left to go."
        }

        let request = UNNotificationRequest(
            identifier: "budget-warning-\(categoryName)-\(Int(percentSpent * 100))",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Bill Reminders

    func scheduleBillReminder(
        billName: String,
        amount: String,
        dueDate: Date,
        daysBefore: Int = 1
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Bill coming up 💡"
        content.body = "\(billName) (\(amount)) is due \(daysBefore == 0 ? "today" : "tomorrow")."
        content.sound = .default
        content.categoryIdentifier = "bill-reminder"

        let triggerDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: dueDate) ?? dueDate
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: triggerDate)
        var notifComponents = components
        notifComponents.hour = 9 // Send at 9 AM

        let trigger = UNCalendarNotificationTrigger(dateMatching: notifComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "bill-\(billName)-\(dueDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Weekly Summary

    func scheduleWeeklySummary(dayOfWeek: Int = 1, hour: Int = 19) {
        let content = UNMutableNotificationContent()
        content.title = "Your week in review 📊"
        content.body = "Tap to see how your spending looked this week."
        content.sound = .default
        content.categoryIdentifier = "weekly-summary"

        var dateComponents = DateComponents()
        dateComponents.weekday = dayOfWeek
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly-summary",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Goal Milestones

    func scheduleGoalMilestone(goalName: String, milestone: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Milestone reached! 🎉"
        content.body = "You're \(milestone)% toward your \(goalName) goal. Keep it up!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "goal-\(goalName)-\(milestone)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cleanup

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func cancelBillReminders() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let billIds = requests.filter { $0.identifier.hasPrefix("bill-") }.map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: billIds)
        }
    }
}
