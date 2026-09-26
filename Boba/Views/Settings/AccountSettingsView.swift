import SwiftUI
import SwiftData
import AuthenticationServices

/// Dedicated Account Settings view for Apple Sign In, profile management, household sharing, and account deletion.
struct AccountSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var preferences: [UserPreferences]
    @Query private var households: [Household]

    @State private var appleAuth = AppleAuthService.shared
    @State private var appleWallet = AppleWalletService.shared
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var showDeleteConfirmation = false
    @State private var showSignOutConfirmation = false
    @State private var showSavedConfirmation = false
    @State private var walletSyncSuccessMessage: String? = nil

    // Add Custom Card state
    @State private var showAddCardSheet = false
    @State private var newCardName = ""
    @State private var newCardType = "Credit Card"
    @State private var newCardLastFour = ""

    private var prefs: UserPreferences? { preferences.first }
    private var currentHousehold: Household? { households.first }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: BobaSpacing.xl) {
                    // Profile Avatar Hero
                    profileAvatarHero

                    // Household Sharing Section
                    householdCard

                    // Apple Wallet Sync Card (Official App Icon & Card Picker)
                    appleWalletCard

                    // Account Status Card
                    accountStatusCard

                    // Edit Profile Card
                    editProfileCard

                    // Danger Zone
                    dangerZoneCard
                }
                .padding(.horizontal, BobaSpacing.md)
                .padding(.vertical, BobaSpacing.md)
                .padding(.bottom, 60)
            }

            // Save Confirmation Toast
            if showSavedConfirmation {
                VStack {
                    Spacer()
                    HStack(spacing: BobaSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(BobaColors.limeCream)
                            .font(.system(size: 18))
                        Text("Profile Saved")
                            .font(BobaFont.headlineSmall())
                            .foregroundStyle(BobaColors.textPrimary)
                    }
                    .padding(.horizontal, BobaSpacing.lg)
                    .padding(.vertical, BobaSpacing.sm)
                    .background(BobaColors.surfaceElevated)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(BobaColors.limeCream.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
                    .padding(.bottom, BobaSpacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(100)
            }
        }
        .background(BobaColors.background)
        .navigationTitle("Account & Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            loadCurrentProfile()
        }
        .sheet(isPresented: $showAddCardSheet) {
            addCardSheet
        }
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                SupabaseService.shared.signOut()
                if let p = prefs {
                    p.isAppleLinked = false
                    try? modelContext.save()
                }
                BobaHaptics.medium()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out? Your local data will remain saved on this device.")
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Delete Everything", role: .destructive) {
                Task {
                    await SupabaseService.shared.deleteAccount(modelContext: modelContext)
                    BobaHaptics.error()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove your linked account and reset your profile. This action cannot be undone.")
        }
    }

    // MARK: - Profile Avatar Hero

    private var profileAvatarHero: some View {
        VStack(spacing: BobaSpacing.sm) {
            ZStack {
                Circle()
                    .fill(BobaColors.accentGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: BobaColors.fieryTerracotta.opacity(0.35), radius: 10, y: 3)

                Text(avatarInitials)
                    .font(BobaFont.displaySmall())
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text(displayName)
                    .font(BobaFont.headlineLarge())
                    .foregroundStyle(BobaColors.textPrimary)

                if let email = prefs?.email, !email.isEmpty {
                    Text(email)
                        .font(BobaFont.bodyMedium())
                        .foregroundStyle(BobaColors.textTertiary)
                }

                HStack(spacing: BobaSpacing.xxs) {
                    Circle()
                        .fill(BobaColors.limeCream)
                        .frame(width: 7, height: 7)

                    Text("Cloud Sync Active")
                        .font(BobaFont.caption())
                        .foregroundStyle(BobaColors.limeCream)
                }
                .padding(.horizontal, BobaSpacing.sm)
                .padding(.vertical, 4)
                .background(BobaColors.limeCream.opacity(0.12))
                .clipShape(Capsule())
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BobaSpacing.lg)
        .background(BobaColors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.xl))
    }

    // MARK: - Household Sharing Card

    private var householdCard: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.sm) {
            BobaSectionHeader(title: "Household & Sharing")

            NavigationLink {
                HouseholdSettingsView()
            } label: {
                BobaCard {
                    HStack(spacing: BobaSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(BobaColors.limeCream.opacity(0.18))
                                .frame(width: 44, height: 44)

                            Image(systemName: "house.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(BobaColors.limeCream)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentHousehold?.name ?? "Household Budgets")
                                .font(BobaFont.headlineSmall())
                                .foregroundStyle(BobaColors.textPrimary)

                            Text(currentHousehold != nil
                                 ? "\(currentHousehold!.members.count + 1) members · Budgets shared"
                                 : "Invite partners & family by email")
                                .font(BobaFont.bodySmall())
                                .foregroundStyle(BobaColors.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BobaColors.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Apple Wallet Card

    private var appleWalletCard: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.sm) {
            BobaSectionHeader(title: "Apple Wallet & Spendings")

            BobaCard {
                VStack(spacing: BobaSpacing.md) {
                    HStack(spacing: BobaSpacing.md) {
                        // Official Apple Wallet App Icon
                        AppleWalletAppIcon(size: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Wallet & Apple Pay")
                                .font(BobaFont.headlineSmall())
                                .foregroundStyle(BobaColors.textPrimary)

                            if appleWallet.isConnected {
                                Text("Card syncing enabled · Daily auto-import")
                                    .font(BobaFont.bodySmall())
                                    .foregroundStyle(BobaColors.limeCream)
                            } else {
                                Text("Sync card transactions automatically")
                                    .font(BobaFont.bodySmall())
                                    .foregroundStyle(BobaColors.textTertiary)
                            }
                        }

                        Spacer()

                        if appleWallet.isConnected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(BobaColors.limeCream)
                                .font(.system(size: 20))
                        }
                    }

                    if appleWallet.isConnected {
                        Divider()
                            .background(BobaColors.surfaceSecondary)

                        // Cards Selection Section
                        VStack(alignment: .leading, spacing: BobaSpacing.xs) {
                            HStack {
                                Text("SELECT CARDS TO SYNC")
                                    .font(BobaFont.overline())
                                    .foregroundStyle(BobaColors.textTertiary)
                                    .tracking(1)

                                Spacer()

                                Button {
                                    appleWallet.fetchSystemWalletCards()
                                    BobaHaptics.selection()
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Scan Wallet")
                                    }
                                    .font(BobaFont.caption().bold())
                                    .foregroundStyle(BobaColors.limeCream)
                                }
                            }

                            VStack(spacing: BobaSpacing.xs) {
                                ForEach(appleWallet.availableCards) { card in
                                    Button {
                                        appleWallet.toggleCardSelection(id: card.id)
                                    } label: {
                                        HStack(spacing: BobaSpacing.sm) {
                                            Image(systemName: card.icon)
                                                .font(.system(size: 14))
                                                .foregroundStyle(card.isSelected ? BobaColors.limeCream : BobaColors.textTertiary)
                                                .frame(width: 32, height: 32)
                                                .background(BobaColors.surfaceElevated)
                                                .clipShape(Circle())

                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(card.name)
                                                    .font(BobaFont.bodyMedium().bold())
                                                    .foregroundStyle(BobaColors.textPrimary)

                                                Text("\(card.cardType) ···· \(card.lastFour)")
                                                    .font(BobaFont.caption())
                                                    .foregroundStyle(BobaColors.textTertiary)
                                            }

                                            Spacer()

                                            Image(systemName: card.isSelected ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 20))
                                                .foregroundStyle(card.isSelected ? BobaColors.limeCream : BobaColors.textTertiary)
                                        }
                                        .padding(BobaSpacing.xs)
                                        .background(BobaColors.surfaceElevated.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: BobaRadius.md)
                                                .stroke(card.isSelected ? BobaColors.limeCream.opacity(0.3) : BobaColors.surfaceSecondary, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button {
                                    showAddCardSheet = true
                                    BobaHaptics.selection()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Custom Card / Payment Method")
                                    }
                                    .font(BobaFont.caption().bold())
                                    .foregroundStyle(BobaColors.limeCream)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(BobaColors.surfaceElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                                }
                                .buttonStyle(BobaPressableButtonStyle())
                            }
                        }

                        Divider()
                            .background(BobaColors.surfaceSecondary)

                        HStack {
                            if let lastSync = appleWallet.lastSyncDate {
                                Text("Last synced \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                                    .font(BobaFont.caption())
                                    .foregroundStyle(BobaColors.textTertiary)
                            } else {
                                Text("Ready to sync")
                                    .font(BobaFont.caption())
                                    .foregroundStyle(BobaColors.textTertiary)
                            }

                            Spacer()

                            Button {
                                Task {
                                    let count = await appleWallet.syncRecentTransactions(modelContext: modelContext)
                                    walletSyncSuccessMessage = "Synced \(count) transaction\(count == 1 ? "" : "s") from Apple Wallet"
                                    BobaHaptics.success()
                                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                                    walletSyncSuccessMessage = nil
                                }
                            } label: {
                                if appleWallet.isSyncing {
                                    ProgressView()
                                        .tint(BobaColors.limeCream)
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                        Text("Sync Now")
                                    }
                                    .font(BobaFont.caption().bold())
                                    .foregroundStyle(BobaColors.limeCream)
                                }
                            }
                            .disabled(appleWallet.isSyncing)
                        }

                        if let msg = walletSyncSuccessMessage {
                            Text(msg)
                                .font(BobaFont.caption())
                                .foregroundStyle(BobaColors.limeCream)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(role: .destructive) {
                            appleWallet.disconnectWallet()
                        } label: {
                            Text("Disconnect Apple Wallet")
                                .font(BobaFont.caption())
                                .foregroundStyle(BobaColors.fieryTerracotta)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Button {
                            Task {
                                _ = await appleWallet.connectWallet(modelContext: modelContext)
                            }
                        } label: {
                            HStack(spacing: BobaSpacing.xs) {
                                Image(systemName: "plus.circle.fill")
                                Text("Connect Apple Wallet")
                            }
                            .font(BobaFont.headlineSmall())
                            .foregroundStyle(BobaColors.shadowGrey)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(BobaColors.limeCream)
                            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                        }
                        .buttonStyle(BobaPressableButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: - Add Card Sheet

    private var addCardSheet: some View {
        NavigationStack {
            ZStack {
                BobaColors.background.ignoresSafeArea()

                VStack(spacing: BobaSpacing.md) {
                    VStack(alignment: .leading, spacing: BobaSpacing.xxs) {
                        Text("CARD NAME")
                            .font(BobaFont.overline())
                            .foregroundStyle(BobaColors.textTertiary)

                        TextField("e.g. OTP Visa Platinum / Apple Pay", text: $newCardName)
                            .font(BobaFont.bodyLarge())
                            .foregroundStyle(BobaColors.textPrimary)
                            .padding(BobaSpacing.sm)
                            .background(BobaColors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                    }

                    VStack(alignment: .leading, spacing: BobaSpacing.xxs) {
                        Text("CARD TYPE")
                            .font(BobaFont.overline())
                            .foregroundStyle(BobaColors.textTertiary)

                        Picker("Type", selection: $newCardType) {
                            Text("Credit Card").tag("Credit Card")
                            Text("Debit Card").tag("Debit Card")
                            Text("Transit Pass").tag("Transit Pass")
                            Text("Store Card").tag("Store Card")
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: BobaSpacing.xxs) {
                        Text("LAST 4 DIGITS")
                            .font(BobaFont.overline())
                            .foregroundStyle(BobaColors.textTertiary)

                        TextField("e.g. 4019", text: $newCardLastFour)
                            .font(BobaFont.bodyLarge())
                            .foregroundStyle(BobaColors.textPrimary)
                            .padding(BobaSpacing.sm)
                            .background(BobaColors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                    }

                    Spacer()

                    Button {
                        appleWallet.addCustomCard(name: newCardName, cardType: newCardType, lastFour: newCardLastFour)
                        newCardName = ""
                        newCardLastFour = ""
                        showAddCardSheet = false
                    } label: {
                        Text("Add Card to Wallet Sync")
                            .font(BobaFont.headlineSmall())
                            .foregroundStyle(BobaColors.shadowGrey)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                newCardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? BobaColors.surfaceSecondary
                                    : BobaColors.limeCream
                            )
                            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                    }
                    .disabled(newCardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(BobaSpacing.md)
            }
            .navigationTitle("Add Wallet Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddCardSheet = false }
                        .foregroundStyle(BobaColors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Account Status Card

    private var accountStatusCard: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.sm) {
            BobaSectionHeader(title: "Sign in with Apple")

            BobaCard {
                VStack(spacing: BobaSpacing.md) {
                    if prefs?.isAppleLinked == true {
                        HStack(spacing: BobaSpacing.md) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 28))
                                .foregroundStyle(BobaColors.textPrimary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apple ID Linked")
                                    .font(BobaFont.headlineSmall())
                                    .foregroundStyle(BobaColors.textPrimary)

                                Text(prefs?.email ?? "Secure Cloud Sync Enabled")
                                    .font(BobaFont.bodySmall())
                                    .foregroundStyle(BobaColors.textTertiary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(BobaColors.limeCream)
                                .font(.system(size: 22))
                        }
                    } else {
                        VStack(spacing: BobaSpacing.sm) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Link Apple ID")
                                        .font(BobaFont.headlineSmall())
                                        .foregroundStyle(BobaColors.textPrimary)
                                    Text("Enable automatic encrypted cloud backup and cross-device sync")
                                        .font(BobaFont.bodySmall())
                                        .foregroundStyle(BobaColors.textTertiary)
                                }
                                Spacer()
                            }

                            Button {
                                appleAuth.startSignInWithApple(modelContext: modelContext) { success in
                                    if success {
                                        BobaHaptics.success()
                                    }
                                }
                            } label: {
                                HStack(spacing: BobaSpacing.xs) {
                                    Image(systemName: "applelogo")
                                        .font(.system(size: 18))
                                    Text("Sign in with Apple")
                                        .font(BobaFont.headlineSmall())
                                }
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                            }
                            .buttonStyle(BobaPressableButtonStyle())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Edit Profile Card

    private var editProfileCard: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.sm) {
            BobaSectionHeader(title: "Profile Information")

            BobaCard {
                VStack(spacing: BobaSpacing.md) {
                    VStack(alignment: .leading, spacing: BobaSpacing.xxs) {
                        Text("FIRST NAME")
                            .font(BobaFont.overline())
                            .foregroundStyle(BobaColors.textTertiary)

                        TextField("First Name", text: $firstName)
                            .font(BobaFont.bodyLarge())
                            .foregroundStyle(BobaColors.textPrimary)
                            .padding(BobaSpacing.sm)
                            .background(BobaColors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                    }

                    VStack(alignment: .leading, spacing: BobaSpacing.xxs) {
                        Text("LAST NAME")
                            .font(BobaFont.overline())
                            .foregroundStyle(BobaColors.textTertiary)

                        TextField("Last Name", text: $lastName)
                            .font(BobaFont.bodyLarge())
                            .foregroundStyle(BobaColors.textPrimary)
                            .padding(BobaSpacing.sm)
                            .background(BobaColors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                    }

                    Button {
                        saveProfileChanges()
                    } label: {
                        HStack(spacing: BobaSpacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Settings")
                        }
                        .font(BobaFont.headlineSmall())
                        .foregroundStyle(BobaColors.shadowGrey)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(BobaColors.limeCream)
                        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                    }
                    .buttonStyle(BobaPressableButtonStyle())
                }
            }
        }
    }

    // MARK: - Danger Zone Card

    private var dangerZoneCard: some View {
        VStack(alignment: .leading, spacing: BobaSpacing.sm) {
            BobaSectionHeader(title: "Account Actions")

            BobaCard {
                VStack(spacing: BobaSpacing.sm) {
                    if prefs?.isAppleLinked == true {
                        Button {
                            showSignOutConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                Spacer()
                            }
                            .font(BobaFont.headlineSmall())
                            .foregroundStyle(BobaColors.fieryTerracotta)
                        }

                        Divider()
                            .background(BobaColors.surfaceSecondary)
                    }

                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Account & Reset Data")
                            Spacer()
                        }
                        .font(BobaFont.headlineSmall())
                        .foregroundStyle(Color.red)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var displayName: String {
        let full = [firstName, lastName].filter({ !$0.isEmpty }).joined(separator: " ")
        return full.isEmpty ? "Boba Member" : full
    }

    private var avatarInitials: String {
        let f = firstName.prefix(1)
        let l = lastName.prefix(1)
        if !f.isEmpty || !l.isEmpty {
            return "\(f)\(l)".uppercased()
        }
        return "B"
    }

    private func loadCurrentProfile() {
        if let p = prefs {
            firstName = p.firstName
            lastName = p.lastName
        }
    }

    private func saveProfileChanges() {
        if let p = prefs {
            p.firstName = firstName.trimmingCharacters(in: .whitespaces)
            p.lastName = lastName.trimmingCharacters(in: .whitespaces)
            try? modelContext.save()
            NotificationCenter.default.post(name: .bobaDataDidChange, object: nil)
            BobaHaptics.success()

            withAnimation(BobaAnimation.quick) {
                showSavedConfirmation = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(BobaAnimation.quick) {
                    showSavedConfirmation = false
                }
            }
        }
    }
}
