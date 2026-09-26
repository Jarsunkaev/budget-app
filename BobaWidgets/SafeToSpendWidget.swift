import WidgetKit
import SwiftUI

// MARK: - Widget-Local Types

/// Budget health states (local copy for widget target)
enum WidgetBudgetHealth {
    case excellent, good, caution, warning, overBudget

    var message: String {
        switch self {
        case .excellent: return "Looking great!"
        case .good: return "On track"
        case .caution: return "Getting warm"
        case .warning: return "Almost there"
        case .overBudget: return "Let's adjust"
        }
    }
}

/// Color helper for widget (local copy)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

/// Widget color palette (local copy)
enum WidgetColors {
    static let shadowGrey = Color(hex: "221d23")
    static let surfacePrimary = Color(hex: "2e2831")
    static let surfaceSecondary = Color(hex: "3a3340")
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.45)
    static let fieryTerracotta = Color(hex: "d1603d")
    static let metallicGold = Color(hex: "ddb967")
    static let limeCream = Color(hex: "d0e37f")
}

// MARK: - Widget Timeline Provider

struct SafeToSpendProvider: TimelineProvider {
    func placeholder(in context: Context) -> SafeToSpendEntry {
        SafeToSpendEntry(date: .now, safeToSpend: "€1,234", dailyBudget: "€41/day", daysLeft: 15, health: .good)
    }

    func getSnapshot(in context: Context, completion: @escaping (SafeToSpendEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SafeToSpendEntry>) -> Void) {
        // In production, this would query the shared SwiftData container for real values
        let calendar = Calendar.current
        let now = Date()
        let range = calendar.range(of: .day, in: .month, for: now)
        let currentDay = calendar.component(.day, from: now)
        let daysLeft = (range?.count ?? 30) - currentDay

        let entry = SafeToSpendEntry(
            date: now,
            safeToSpend: "€1,234",
            dailyBudget: "€41/day",
            daysLeft: daysLeft,
            health: .good
        )

        // Refresh every hour
        let nextUpdate = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Entry

struct SafeToSpendEntry: TimelineEntry {
    let date: Date
    let safeToSpend: String
    let dailyBudget: String
    let daysLeft: Int
    let health: WidgetBudgetHealth
}

// MARK: - Small Widget View

struct SafeToSpendSmallView: View {
    var entry: SafeToSpendEntry

    private var healthColor: Color {
        switch entry.health {
        case .excellent, .good: return WidgetColors.limeCream
        case .caution: return WidgetColors.metallicGold
        case .warning, .overBudget: return WidgetColors.fieryTerracotta
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("🧋")
                    .font(.system(size: 16))
                Spacer()
                Text(entry.health.message)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(healthColor)
            }

            Spacer()

            Text("Safe to Spend")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(WidgetColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.8)

            Text(entry.safeToSpend)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetColors.textPrimary)
                .minimumScaleFactor(0.7)

            Text("\(entry.dailyBudget) · \(entry.daysLeft)d left")
                .font(.system(size: 10))
                .foregroundStyle(WidgetColors.textTertiary)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            WidgetColors.surfacePrimary
        }
    }
}

// MARK: - Medium Widget View

struct SafeToSpendMediumView: View {
    var entry: SafeToSpendEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("🧋")
                        .font(.system(size: 18))
                    Text("Boba")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WidgetColors.textSecondary)
                }

                Spacer()

                Text("Safe to Spend")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(WidgetColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(entry.safeToSpend)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetColors.textPrimary)

                Text("\(entry.dailyBudget) · \(entry.daysLeft) days left")
                    .font(.system(size: 12))
                    .foregroundStyle(WidgetColors.textTertiary)
            }

            Spacer()

            // Ring progress indicator
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(WidgetColors.surfaceSecondary, lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: 0.65)
                        .stroke(WidgetColors.limeCream, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 70, height: 70)

                Text("65%")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetColors.textSecondary)
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            WidgetColors.surfacePrimary
        }
    }
}

// MARK: - Lock Screen Widget (Circular)

struct SafeToSpendLockScreenView: View {
    var entry: SafeToSpendEntry

    var body: some View {
        VStack(spacing: 2) {
            Text("🧋")
                .font(.system(size: 12))
            Text(entry.safeToSpend)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

// MARK: - Widget Definition

struct SafeToSpendWidget: Widget {
    let kind = "SafeToSpendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SafeToSpendProvider()) { entry in
            SafeToSpendSmallView(entry: entry)
        }
        .configurationDisplayName("Safe to Spend")
        .description("See how much you can safely spend at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}

// MARK: - Widget Bundle

@main
struct BobaWidgetBundle: WidgetBundle {
    var body: some Widget {
        SafeToSpendWidget()
    }
}

#Preview("Small", as: .systemSmall) {
    SafeToSpendWidget()
} timeline: {
    SafeToSpendEntry(date: .now, safeToSpend: "€1,234", dailyBudget: "€41/day", daysLeft: 15, health: .good)
}

#Preview("Medium", as: .systemMedium) {
    SafeToSpendWidget()
} timeline: {
    SafeToSpendEntry(date: .now, safeToSpend: "€1,234", dailyBudget: "€41/day", daysLeft: 15, health: .good)
}
