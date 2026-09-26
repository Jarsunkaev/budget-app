import SwiftUI
import SwiftData

/// Boba — Your warm, friendly budget companion. 🧋
@main
struct BobaApp: App {
    @State private var hasCompletedOnboarding = false
    @State private var isAuthenticated = false
    @State private var needsAuth = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self,
            Budget.self,
            Account.self,
            RecurringTransaction.self,
            UserPreferences.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // Enable .automatic for CloudKit sync in Phase 2
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if needsAuth && !isAuthenticated {
                    lockScreen
                } else if !hasCompletedOnboarding {
                    OnboardingContainerView {
                        withAnimation(BobaAnimation.standard) {
                            hasCompletedOnboarding = true
                        }
                    }
                } else {
                    ContentView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                NavigationLink {
                                    SettingsView()
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .foregroundStyle(BobaColors.textSecondary)
                                }
                            }
                        }
                }
            }
            .modelContainer(sharedModelContainer)
            .preferredColorScheme(.dark)
            .onAppear {
                checkOnboardingStatus()
                checkBiometricPreference()
            }
        }
    }

    // MARK: - Lock Screen

    private var lockScreen: some View {
        ZStack {
            BobaColors.background.ignoresSafeArea()

            VStack(spacing: BobaSpacing.xl) {
                Text("🧋")
                    .font(.system(size: 60))

                Text("Boba is locked")
                    .font(BobaFont.headlineLarge())
                    .foregroundStyle(BobaColors.textPrimary)

                Button {
                    Task {
                        isAuthenticated = await BiometricService.shared.authenticate()
                    }
                } label: {
                    HStack {
                        Image(systemName: BiometricService.shared.biometricIcon)
                        Text("Unlock with \(BiometricService.shared.biometricName)")
                    }
                    .font(BobaFont.headlineMedium())
                    .foregroundStyle(.white)
                    .padding(.horizontal, BobaSpacing.xxl)
                    .frame(height: 52)
                    .background(BobaColors.fieryTerracotta)
                    .clipShape(RoundedRectangle(cornerRadius: BobaRadius.lg))
                }
            }
        }
        .onAppear {
            Task {
                isAuthenticated = await BiometricService.shared.authenticate()
            }
        }
    }

    // MARK: - Helpers

    @MainActor
    private func checkOnboardingStatus() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<UserPreferences>()
        let prefs = (try? context.fetch(descriptor))?.first
        hasCompletedOnboarding = prefs?.hasCompletedOnboarding ?? false
    }

    @MainActor
    private func checkBiometricPreference() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<UserPreferences>()
        let prefs = (try? context.fetch(descriptor))?.first
        needsAuth = prefs?.biometricEnabled ?? false
    }
}
