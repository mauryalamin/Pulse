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
    @Published var isAuthenticating = false
    
    init() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            isUnlocked = true // Unlock for Previews!
        }
    }

    func authenticate() async {
        guard !isUnlocked && !isAuthenticating else {
            print("🚫 Already unlocked or in progress")
            return
        }
        print("🔐 Starting Face ID Auth")
        isAuthenticating = true
        defer { isAuthenticating = false }

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock Pulse"
            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
                if success {
                    print("✅ Face ID Success")
                    isUnlocked = true
                }
            } catch {
                print("❌ Face ID failed: \(error.localizedDescription)")
                isUnlocked = false
            }
        } else {
            print("❌ Face ID not available")
            isUnlocked = false
        }
    }

    func handleDidEnterBackground() {
        backgroundEnteredAt = Date()
        isUnlocked = false // 🔐 Lock immediately when app backgrounds
        print("🌙 Entered background at \(backgroundEnteredAt!) — UI locked")
    }

    func handleWillEnterForeground() {
        guard let enteredAt = backgroundEnteredAt else { return }

        let elapsed = Date().timeIntervalSince(enteredAt)
        guard elapsed > 20 else {
            print("⏱ Less than 20s in background, skipping auth")
            return
        }

        print("🔒 Background exceeded 20s, requiring Face ID")
        print("🔐 isUnlocked: \(isUnlocked), isAuthenticating: \(isAuthenticating)")
        if !isUnlocked && !isAuthenticating {
            isUnlocked = false
            Task { await authenticate() }
        }
    }
    
    private var backgroundEnteredAt: Date?
}
