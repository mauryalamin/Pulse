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
    private let biometricsPreferenceKey = "useBiometrics"

    // Observable UI state
    var isUnlocked: Bool = false
    var authError: String?
    var isAuthenticating = false

    private var backgroundEnteredAt: Date?
    var isBiometricsEnabled: Bool {
        UserDefaults.standard.bool(forKey: biometricsPreferenceKey)
    }
    var shouldLockUI: Bool {
        isBiometricsEnabled && !isUnlocked
    }

    init() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            isUnlocked = true // Unlock for Previews!
        } else {
            isUnlocked = !isBiometricsEnabled
        }
    }

    func authenticate() async {
        guard isBiometricsEnabled else {
            isUnlocked = true
            authError = nil
            return
        }

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

    @discardableResult
    func requestBiometricsOptIn() async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authError = "Biometrics unavailable"
            UserDefaults.standard.set(false, forKey: biometricsPreferenceKey)
            isUnlocked = true
            return false
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Enable Face ID for Pulse"
            )
            if success {
                UserDefaults.standard.set(true, forKey: biometricsPreferenceKey)
                isUnlocked = true
                authError = nil
                return true
            }
            UserDefaults.standard.set(false, forKey: biometricsPreferenceKey)
            isUnlocked = true
            return false
        } catch {
            authError = error.localizedDescription
            UserDefaults.standard.set(false, forKey: biometricsPreferenceKey)
            isUnlocked = true
            return false
        }
    }

    func disableBiometrics() {
        UserDefaults.standard.set(false, forKey: biometricsPreferenceKey)
        isUnlocked = true
        authError = nil
    }

    func handleDidEnterBackground() {
        backgroundEnteredAt = Date()
        if isBiometricsEnabled {
            isUnlocked = false // 🔐 Lock immediately when app backgrounds
        }
        print("🌙 Entered background at \(backgroundEnteredAt!) — UI locked")
    }

    func handleWillEnterForeground() {
        guard isBiometricsEnabled else {
            isUnlocked = true
            return
        }

        guard let enteredAt = backgroundEnteredAt else { return }
        let elapsed = Date().timeIntervalSince(enteredAt)
        guard elapsed > 20 else {
            print("⏱ Less than 20s in background, skipping auth")
            isUnlocked = true
            return
        }
        print("🔒 Background exceeded 20s, requiring Face ID")
        if !isUnlocked && !isAuthenticating {
            isUnlocked = false
            Task { await authenticate() }
        }
    }
}
