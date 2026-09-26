import Foundation
import SwiftData

/// Represents a shared household budget group.
/// Allows inviting members by email so invitees can view the inviter's budgets.
@Model
final class Household {
    var id: UUID
    var name: String
    var ownerEmail: String
    var membersRaw: String
    var pendingInvitesRaw: String
    var isSharedBudgetActive: Bool
    var createdAt: Date
    var updatedAt: Date

    var members: [String] {
        get {
            guard !membersRaw.isEmpty else { return [] }
            return membersRaw.components(separatedBy: ",").filter { !$0.isEmpty }
        }
        set {
            membersRaw = newValue.joined(separator: ",")
        }
    }

    var pendingInvites: [String] {
        get {
            guard !pendingInvitesRaw.isEmpty else { return [] }
            return pendingInvitesRaw.components(separatedBy: ",").filter { !$0.isEmpty }
        }
        set {
            pendingInvitesRaw = newValue.joined(separator: ",")
        }
    }

    init(
        id: UUID = UUID(),
        name: String = "My Household",
        ownerEmail: String = "",
        members: [String] = [],
        pendingInvites: [String] = [],
        isSharedBudgetActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.ownerEmail = ownerEmail
        self.membersRaw = members.joined(separator: ",")
        self.pendingInvitesRaw = pendingInvites.joined(separator: ",")
        self.isSharedBudgetActive = isSharedBudgetActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func invite(email: String) {
        let clean = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return }
        var current = pendingInvites
        if !current.contains(clean) && !members.contains(clean) {
            current.append(clean)
            pendingInvites = current
            updatedAt = .now
        }
    }

    func cancelInvite(email: String) {
        var current = pendingInvites
        current.removeAll { $0.caseInsensitiveCompare(email) == .orderedSame }
        pendingInvites = current
        updatedAt = .now
    }

    func removeMember(email: String) {
        var current = members
        current.removeAll { $0.caseInsensitiveCompare(email) == .orderedSame }
        members = current
        updatedAt = .now
    }
}
