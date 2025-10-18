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
    @AppStorage("isStealthModeEnabled") var isStealthModeEnabled: Bool = false
    @AppStorage("selectedStealthIcon") var selectedStealthIcon: String?

    @Environment(\.scenePhase) private var scenePhase
    @State private var lock = AppLockManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if isOnboarding {
                    OnboardingFlowView()
                } else {
                    ZStack {
                        ContentStartupWrapper()
                            .environment(lock)
                            .blur(radius: lock.isUnlocked ? 0 : 30)
                            .animation(.easeInOut(duration: 0.4), value: lock.isUnlocked)

                        if !lock.isUnlocked {
                            Color.clear
                                .background(.ultraThinMaterial)
                                .ignoresSafeArea()
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.4), value: lock.isUnlocked)

                            VStack(spacing: 16) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.secondary)

                                Text("Unlocking with Face ID...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.4), value: lock.isUnlocked)
                        }
                    }
                    .task {
                        if !lock.isUnlocked {
                            await lock.authenticate()
                        }
                    }
                    .onChange(of: scenePhase) {
                        switch scenePhase {
                        case .background:
                            lock.handleDidEnterBackground()
                        case .active:
                            lock.handleWillEnterForeground()
                        default:
                            break
                        }
                    }
                }
            }
            // Provide Observation-style environment + SwiftData models
            
        }
        .modelContainer(for: [Moment.self, Urge.self, Tag.self])
    }
}
