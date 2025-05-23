//
//  PulseApp.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import SwiftUI
import SwiftData

@main
struct PulseApp: App {

    @AppStorage("isOnboarding") var isOnboarding: Bool = true
    @StateObject private var biometricManager = BiometricAuthManager()

    var body: some Scene {
        WindowGroup {
            if isOnboarding {
                OnboardingFlowView()
            } else {
                ZStack {
                    if biometricManager.isUnlocked {
                        ContentStartupWrapper()
                            .modelContainer(for: [Moment.self, Urge.self])
                    } else {
                        Color(.systemBackground)
                            .ignoresSafeArea()
                        // Optional placeholder or blur
                        ProgressView("Authenticating...")
                    }
                }
                .task {
                    await biometricManager.authenticate()
                }
            }
        }
    }
}
