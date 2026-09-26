import Foundation
import LocalAuthentication

/// Handles Face ID / Touch ID authentication for app lock.
final class BiometricService {
    static let shared = BiometricService()

    private init() {}

    /// The type of biometric available on this device.
    var biometricType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    /// Human-readable name for the available biometric.
    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biometric"
        }
    }

    /// SF Symbol for the available biometric.
    var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock.fill"
        }
    }

    /// Whether biometric authentication is available.
    var isAvailable: Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    /// Authenticate the user with biometrics.
    func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fall back to device passcode
            return await authenticateWithPasscode()
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Boba to access your finances"
            )
        } catch {
            print("Biometric auth failed: \(error)")
            return false
        }
    }

    /// Fallback to device passcode authentication.
    private func authenticateWithPasscode() async -> Bool {
        let context = LAContext()
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock Boba to access your finances"
            )
        } catch {
            print("Passcode auth failed: \(error)")
            return false
        }
    }
}
