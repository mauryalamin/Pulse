//
//  BiometricAuthManager.swift
//  Pulse
//
//  Created by Maury Alamin on 5/23/25.
//

import Foundation
import LocalAuthentication

@MainActor
final class BiometricAuthManager: ObservableObject {
    @Published var isUnlocked: Bool = false
    @Published var authError: String?

    func authenticate() async {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authError = "Biometric authentication not available."
            return
        }

        let reason = "Unlock Pulse"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if success {
                isUnlocked = true
            } else {
                authError = "Authentication failed."
            }
        } catch {
            authError = error.localizedDescription
        }
    }
}
