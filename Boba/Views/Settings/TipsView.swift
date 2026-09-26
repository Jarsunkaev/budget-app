import SwiftUI

/// Tips & Guides screen showing how to get the most out of Boba.
/// Modeled after Apple's native Tips interface with hero card and official squircle iconography.
struct TipsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: BobaSpacing.lg) {
                // MARK: - Hero Card
                heroCard

                // MARK: - Grouped Tips Card
                tipsGroupCard
            }
            .padding(.horizontal, BobaSpacing.md)
            .padding(.vertical, BobaSpacing.md)
            .padding(.bottom, 60)
        }
        .background(BobaColors.background.ignoresSafeArea())
        .navigationTitle("Tips")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.md) {
            // Squircle Yellow Lightbulb Icon Badge
            SettingsSquircleIcon(
                icon: "lightbulb.fill",
                backgroundColor: Color(hex: "FFCC00"),
                iconColor: .white,
                size: 52,
                iconSize: 28
            )

            VStack(alignment: .leading, spacing: BobaSpacing.xxs) {
                Text("Tips & Quick Actions")
                    .font(BobaFont.headlineLarge().bold())
                    .foregroundStyle(BobaColors.textPrimary)

                Text("Start logging expenses from the Action Button, Control Center, Lock Screen widgets, and Siri dictation.")
                    .font(BobaFont.bodyMedium())
                    .foregroundStyle(BobaColors.textSecondary)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BobaSpacing.lg)
        .background(BobaColors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BobaRadius.xl, style: .continuous)
                .stroke(BobaColors.surfaceSecondary.opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Grouped Tips Card

    private var tipsGroupCard: some View {
        VStack(spacing: 0) {
            // 1. Action Button
            tipRow(
                icon: "button.programmable",
                backgroundColor: Color(hex: "FF9500"),
                title: "Action Button",
                description: "On supported iPhone models (15 Pro and newer), open iOS Settings > Action Button, and select Boba to log expenses in 2 seconds with one press."
            )

            divider

            // 2. Control Center
            tipRow(
                icon: "slider.horizontal.2.square",
                backgroundColor: Color(hex: "8E8E93"),
                title: "Control Center",
                description: "Swipe down from the top right, tap Edit, and add the Boba Quick Add control. Record expenses in one tap without unlocking your phone."
            )

            divider

            // 3. Lock Screen & Home Widgets
            tipRow(
                icon: "iphone",
                backgroundColor: Color(hex: "007AFF"),
                title: "Lock Screen & Widgets",
                description: "Long press your Lock Screen or Home Screen, tap Customize, and add the Safe-to-Spend widget for a real-time spending balance at a glance."
            )

            divider

            // 4. Smart Log & Siri
            tipRow(
                icon: "waveform",
                backgroundColor: Color(hex: "1C1C1E"),
                title: "Smart Log & Siri",
                description: "Tap the microphone or use Siri Shortcuts. Say phrases like '12€ for coffee' or 'Received 2500€ salary' — AI automatically categorizes and extracts amounts."
            )

            divider

            // 5. Envelope Budgeting
            tipRow(
                icon: "envelope.fill",
                backgroundColor: Color(hex: "34C759"),
                title: "Envelope Budgeting",
                description: "Envelopes track spending caps for your everyday expenses. Income is tracked purely as cash inflow so your envelope limits stay clean and disciplined."
            )

            divider

            // 6. Automatic Rollovers
            tipRow(
                icon: "arrow.triangle.2.circlepath",
                backgroundColor: Color(hex: "5856D6"),
                title: "Rollover to Savings",
                description: "Enable 'Roll over unspent to Savings' on any budget. Any unspent balance remaining in your envelopes will automatically sweep into your accumulated savings."
            )
        }
        .background(BobaColors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BobaRadius.xl, style: .continuous)
                .stroke(BobaColors.surfaceSecondary.opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Row Helper

    private func tipRow(
        icon: String,
        backgroundColor: Color,
        title: String,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: BobaSpacing.md) {
            SettingsSquircleIcon(
                icon: icon,
                backgroundColor: backgroundColor,
                iconColor: .white,
                size: 34,
                iconSize: 18
            )
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: BobaSpacing.xxxs) {
                Text(title)
                    .font(BobaFont.headlineSmall())
                    .foregroundStyle(BobaColors.textPrimary)

                Text(description)
                    .font(BobaFont.bodySmall())
                    .foregroundStyle(BobaColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, BobaSpacing.md)
        .padding(.vertical, BobaSpacing.md)
    }

    private var divider: some View {
        Divider()
            .background(BobaColors.surfaceSecondary.opacity(0.7))
            .padding(.leading, 58)
    }
}

#Preview {
    NavigationStack {
        TipsView()
    }
}
