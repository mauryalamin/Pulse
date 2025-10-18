//
//  AppLockManager.swift
//  Pulse
//
//  Created by Maury Alamin on 5/23/25.
//

import Foundation
import LocalAuthentication
import Observation

@MainActor
@Observable
final class AppLockManager {
    static let shared = AppLockManager()

    // Observable UI state
    var isUnlocked: Bool = false
    var authError: String?
    var isAuthenticating = false

    private var backgroundEnteredAt: Date?

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
                let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                                               localizedReason: reason)
                if success {
                    print("✅ Face ID Success")
                    isUnlocked = true
                    authError = nil
                }
            } catch {
                print("❌ Face ID failed: \(error.localizedDescription)")
                isUnlocked = false
                authError = error.localizedDescription
            }
        } else {
            print("❌ Face ID not available")
            isUnlocked = false
            authError = "Biometrics unavailable"
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
        if !isUnlocked && !isAuthenticating {
            isUnlocked = false
            Task { await authenticate() }
        }
    }
}
