import SwiftUI
import SwiftData

/// Navigation tabs in Boba.
enum BobaTab: Int, CaseIterable, Identifiable {
    case home = 0
    case transactions = 1
    case budgets = 2
    case reports = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .transactions: return "Transactions"
        case .budgets: return "Budgets"
        case .reports: return "Reports"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .transactions: return "list.bullet"
        case .budgets: return "chart.pie.fill"
        case .reports: return "chart.xyaxis.line"
        }
    }
}

/// Root tab view — the main container after onboarding with custom bottom bar.
struct ContentView: View {
    @State private var selectedTab: BobaTab = .home
    @State private var showAddTransaction = false
    @Namespace private var navNamespace

    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView(onNavigateToBudgets: {
                    navigateToBudgets()
                })
                .tag(BobaTab.home)
                .toolbar(.hidden, for: .tabBar)

                TransactionListView()
                    .tag(BobaTab.transactions)
                    .toolbar(.hidden, for: .tabBar)

                BudgetOverviewView()
                    .tag(BobaTab.budgets)
                    .toolbar(.hidden, for: .tabBar)

                ReportsView()
                    .tag(BobaTab.reports)
                    .toolbar(.hidden, for: .tabBar)
            }
            .toolbar(.hidden, for: .tabBar)

            // Custom floating liquid glass bottom bar
            customBottomBar
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(for: .bobaNavigateToBudgets)) { _ in
            navigateToBudgets()
        }
        .sheet(isPresented: $showAddTransaction, onDismiss: {
            NotificationCenter.default.post(name: .bobaDataDidChange, object: nil)
        }) {
            AddTransactionView()
        }
    }

    private func navigateToBudgets() {
        BobaHaptics.selection()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedTab = .budgets
        }
    }

    // MARK: - Custom Floating Liquid Glass Bar

    private var customBottomBar: some View {
        HStack(spacing: 0) {
            tabButton(.home)
            tabButton(.transactions)

            // Center Tactile Add Button
            Button {
                BobaHaptics.medium()
                showAddTransaction = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    BobaColors.fieryTerracotta,
                                    Color(hex: "#E0532B")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.35),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: BobaColors.fieryTerracotta.opacity(0.45), radius: 8, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(BobaPressableButtonStyle())
            .frame(maxWidth: .infinity)

            tabButton(.budgets)
            tabButton(.reports)
        }
        .padding(.horizontal, BobaSpacing.xs)
        .frame(height: 60)
        .liquidGlassCapsule(.regular)
        .shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 8)
        .padding(.horizontal, BobaSpacing.md)
        .padding(.bottom, 12)
    }

    private func tabButton(_ tab: BobaTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            if tab == .home {
                if selectedTab == .home {
                    NotificationCenter.default.post(name: .bobaResetHomeNavigation, object: nil)
                } else {
                    BobaHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = .home
                    }
                    NotificationCenter.default.post(name: .bobaResetHomeNavigation, object: nil)
                }
            } else {
                if selectedTab != tab {
                    BobaHaptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                }
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(
                        isSelected ? BobaColors.fieryTerracotta : BobaColors.textTertiary
                    )
                    .scaleEffect(isSelected ? 1.12 : 1.0)
                    .shadow(color: isSelected ? BobaColors.fieryTerracotta.opacity(0.4) : Color.clear, radius: 4, y: 1)

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? BobaColors.textPrimary : BobaColors.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
