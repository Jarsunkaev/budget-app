import SwiftUI
import SwiftData

/// Household budget sharing management.
/// Allows creating households, inviting members via email, and sharing budget visibility.
struct HouseholdSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var households: [Household]
    @Query private var preferences: [UserPreferences]

    @State private var newHouseholdName: String = ""
    @State private var inviteEmail: String = ""
    @State private var showCreateSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var inviteSuccessMessage: String? = nil

    private var currentHousehold: Household? {
        households.first
    }

    private var prefs: UserPreferences? {
        preferences.first
    }

    private var userEmail: String {
        prefs?.email ?? "you@example.com"
    }

    var body: some View {
        List {
            if let household = currentHousehold {
                // Active household overview
                householdHeaderSection(household)

                // Invite member section
                inviteMemberSection(household)

                // Active members
                membersSection(household)

                // Pending invites
                pendingInvitesSection(household)

                // Sharing controls
                sharingOptionsSection(household)

                // Danger zone
                dangerZoneSection(household)
            } else {
                // No household state & create CTA
                noHouseholdHero
                createHouseholdSection
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(BobaColors.background)
        .navigationTitle("Household")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showCreateSheet) {
            createHouseholdSheet
        }
        .alert("Delete Household", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let h = currentHousehold {
                    modelContext.delete(h)
                    try? modelContext.save()
                    NotificationCenter.default.post(name: .bobaDataDidChange, object: nil)
                    BobaHaptics.error()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this household? Shared budgets will no longer be visible to invited members.")
        }
    }

    // MARK: - No Household State

    private var noHouseholdHero: some View {
        Section {
            VStack(spacing: BobaSpacing.md) {
                ZStack {
                    Circle()
                        .fill(BobaColors.limeCream.opacity(0.15))
                        .frame(width: 70, height: 70)

                    Image(systemName: "house.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(BobaColors.limeCream)
                }

                VStack(spacing: BobaSpacing.xxs) {
                    Text("Share Budgets with Household")
                        .font(BobaFont.headlineLarge())
                        .foregroundStyle(BobaColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Invite partners, family members, or roommates using their email address. Invitees will be able to view your shared budgets and spending progress.")
                        .font(BobaFont.bodyMedium())
                        .foregroundStyle(BobaColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BobaSpacing.md)
            .listRowBackground(BobaColors.surfacePrimary)
        }
    }

    private var createHouseholdSection: some View {
        Section {
            VStack(alignment: .leading, spacing: BobaSpacing.sm) {
                Text("HOUSEHOLD NAME")
                    .font(BobaFont.overline())
                    .foregroundStyle(BobaColors.textTertiary)

                TextField("e.g. Smith Family, Maple Flat", text: $newHouseholdName)
                    .font(BobaFont.bodyLarge())
                    .foregroundStyle(BobaColors.textPrimary)
                    .padding(BobaSpacing.md)
                    .background(BobaColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))

                Button {
                    createHousehold()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Household")
                    }
                    .font(BobaFont.headlineMedium())
                    .foregroundStyle(BobaColors.shadowGrey)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        newHouseholdName.trimmingCharacters(in: .whitespaces).isEmpty
                            ? BobaColors.limeCream.opacity(0.4)
                            : BobaColors.limeCream
                    )
                    .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                }
                .disabled(newHouseholdName.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(BobaPressableButtonStyle())
            }
            .padding(.vertical, BobaSpacing.xs)
            .listRowBackground(BobaColors.surfacePrimary)
        }
    }

    // MARK: - Active Household Sections

    private func householdHeaderSection(_ household: Household) -> some View {
        Section {
            HStack(spacing: BobaSpacing.md) {
                ZStack {
                    Circle()
                        .fill(BobaColors.accentGradient)
                        .frame(width: 52, height: 52)

                    Image(systemName: "house.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(household.name)
                        .font(BobaFont.headlineLarge())
                        .foregroundStyle(BobaColors.textPrimary)

                    Text("Created by \(household.ownerEmail.isEmpty ? userEmail : household.ownerEmail)")
                        .font(BobaFont.caption())
                        .foregroundStyle(BobaColors.textTertiary)
                }

                Spacer()

                Text("Active")
                    .font(BobaFont.caption())
                    .foregroundStyle(BobaColors.limeCream)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(BobaColors.limeCream.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(.vertical, BobaSpacing.xs)
            .listRowBackground(BobaColors.surfacePrimary)
        }
    }

    private func inviteMemberSection(_ household: Household) -> some View {
        Section("Invite Member by Email") {
            VStack(alignment: .leading, spacing: BobaSpacing.sm) {
                Text("Enter the email address of the person you want to invite. They will receive access to view your budgets.")
                    .font(BobaFont.bodySmall())
                    .foregroundStyle(BobaColors.textSecondary)

                HStack(spacing: BobaSpacing.xs) {
                    TextField("member@example.com", text: $inviteEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .font(BobaFont.bodyMedium())
                        .foregroundStyle(BobaColors.textPrimary)
                        .padding(BobaSpacing.sm)
                        .background(BobaColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))

                    Button {
                        sendInvite(to: household)
                    } label: {
                        Text("Invite")
                            .font(BobaFont.headlineSmall())
                            .foregroundStyle(BobaColors.shadowGrey)
                            .padding(.horizontal, BobaSpacing.md)
                            .frame(height: 42)
                            .background(
                                isValidEmail(inviteEmail)
                                    ? BobaColors.limeCream
                                    : BobaColors.limeCream.opacity(0.4)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: BobaRadius.md))
                    }
                    .disabled(!isValidEmail(inviteEmail))
                }

                if let msg = inviteSuccessMessage {
                    HStack(spacing: BobaSpacing.xxs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(BobaColors.limeCream)
                        Text(msg)
                            .font(BobaFont.caption())
                            .foregroundStyle(BobaColors.limeCream)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.vertical, BobaSpacing.xs)
            .listRowBackground(BobaColors.surfacePrimary)
        }
    }

    private func membersSection(_ household: Household) -> some View {
        Section("Household Members") {
            // Owner row
            HStack(spacing: BobaSpacing.md) {
                ZStack {
                    Circle()
                        .fill(BobaColors.fieryTerracotta.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Text("👑")
                        .font(.system(size: 16))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(household.ownerEmail.isEmpty ? userEmail : household.ownerEmail)
                        .font(BobaFont.headlineSmall())
                        .foregroundStyle(BobaColors.textPrimary)

                    Text("Owner (Inviter)")
                        .font(BobaFont.caption())
                        .foregroundStyle(BobaColors.limeCream)
                }

                Spacer()
            }
            .listRowBackground(BobaColors.surfacePrimary)

            // Joined Members
            ForEach(household.members, id: \.self) { memberEmail in
                HStack(spacing: BobaSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(BobaColors.surfaceSecondary)
                            .frame(width: 36, height: 36)

                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(BobaColors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(memberEmail)
                            .font(BobaFont.headlineSmall())
                            .foregroundStyle(BobaColors.textPrimary)

                        Text("Member · Sees your budgets")
                            .font(BobaFont.caption())
                            .foregroundStyle(BobaColors.textTertiary)
                    }

                    Spacer()

                    Button {
                        household.removeMember(email: memberEmail)
                        try? modelContext.save()
                        BobaHaptics.selection()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(BobaColors.fieryTerracotta)
                    }
                }
                .listRowBackground(BobaColors.surfacePrimary)
            }
        }
    }

    @ViewBuilder
    private func pendingInvitesSection(_ household: Household) -> some View {
        if !household.pendingInvites.isEmpty {
            Section("Pending Invitations") {
                ForEach(household.pendingInvites, id: \.self) { invitee in
                    HStack(spacing: BobaSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(BobaColors.metallicGold.opacity(0.18))
                                .frame(width: 36, height: 36)

                            Image(systemName: "envelope.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(BobaColors.metallicGold)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(invitee)
                                .font(BobaFont.headlineSmall())
                                .foregroundStyle(BobaColors.textPrimary)

                            Text("Invite Sent · Pending Acceptance")
                                .font(BobaFont.caption())
                                .foregroundStyle(BobaColors.metallicGold)
                        }

                        Spacer()

                        Button {
                            household.cancelInvite(email: invitee)
                            try? modelContext.save()
                            BobaHaptics.selection()
                        } label: {
                            Text("Revoke")
                                .font(BobaFont.caption())
                                .foregroundStyle(BobaColors.fieryTerracotta)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(BobaColors.fieryTerracotta.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .listRowBackground(BobaColors.surfacePrimary)
                }
            }
        }
    }

    private func sharingOptionsSection(_ household: Household) -> some View {
        Section("Sharing Options") {
            Toggle(isOn: Binding(
                get: { household.isSharedBudgetActive },
                set: { val in
                    household.isSharedBudgetActive = val
                    try? modelContext.save()
                    NotificationCenter.default.post(name: .bobaDataDidChange, object: nil)
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Share Budget Progress")
                        .font(BobaFont.headlineSmall())
                        .foregroundStyle(BobaColors.textPrimary)

                    Text("Allow household members to view category spending & limits")
                        .font(BobaFont.caption())
                        .foregroundStyle(BobaColors.textTertiary)
                }
            }
            .tint(BobaColors.limeCream)
            .listRowBackground(BobaColors.surfacePrimary)
        }
    }

    private func dangerZoneSection(_ household: Household) -> some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Household")
                }
                .font(BobaFont.headlineSmall())
                .foregroundStyle(BobaColors.fieryTerracotta)
            }
            .listRowBackground(BobaColors.surfacePrimary)
        }
    }

    // MARK: - Actions

    private func createHousehold() {
        let cleanName = newHouseholdName.trimmingCharacters(in: .whitespaces)
        guard !cleanName.isEmpty else { return }

        let h = Household(
            name: cleanName,
            ownerEmail: userEmail,
            members: [],
            pendingInvites: [],
            isSharedBudgetActive: true
        )
        modelContext.insert(h)
        try? modelContext.save()
        newHouseholdName = ""
        NotificationCenter.default.post(name: .bobaDataDidChange, object: nil)
        BobaHaptics.success()
    }

    private func sendInvite(to household: Household) {
        let clean = inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(clean) else { return }

        household.invite(email: clean)
        try? modelContext.save()
        inviteSuccessMessage = "Invitation sent to \(clean)!"
        inviteEmail = ""
        BobaHaptics.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            inviteSuccessMessage = nil
        }
    }

    private func isValidEmail(_ text: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: text)
    }

    private var createHouseholdSheet: some View {
        NavigationStack {
            createHouseholdSection
                .navigationTitle("New Household")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
