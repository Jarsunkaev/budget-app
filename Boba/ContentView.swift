import SwiftUI
import SwiftData

/// Root tab view — the main container after onboarding.
struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showAddTransaction = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                TransactionListView()
                    .tag(1)
                    .tabItem {
                        Label("Transactions", systemImage: "list.bullet")
                    }

                // Placeholder for center add button
                Color.clear
                    .tag(2)
                    .tabItem {
                        Label("Add", systemImage: "plus.circle.fill")
                    }

                BudgetOverviewView()
                    .tag(3)
                    .tabItem {
                        Label("Budgets", systemImage: "chart.pie.fill")
                    }

                ReportsView()
                    .tag(4)
                    .tabItem {
                        Label("Reports", systemImage: "chart.xyaxis.line")
                    }
            }
            .tint(BobaColors.fieryTerracotta)
            .onChange(of: selectedTab) { _, newValue in
                if newValue == 2 {
                    showAddTransaction = true
                    // Reset to previous tab
                    selectedTab = 0
                }
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Transaction.self,
            Category.self,
            Budget.self,
            Account.self,
            RecurringTransaction.self,
            UserPreferences.self
        ], inMemory: true)
}
