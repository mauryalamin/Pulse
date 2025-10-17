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
    
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var biometricManager = BiometricAuthManager()
    
    var body: some Scene {
        WindowGroup {
            if isOnboarding {
                OnboardingFlowView()
            } else {
                ZStack {
                    ContentStartupWrapper()
                        .modelContainer(for: [Moment.self, Urge.self])
                        .environmentObject(biometricManager)
                        .blur(radius: biometricManager.isUnlocked ? 0 : 30)
                        .animation(.easeInOut(duration: 0.4), value: biometricManager.isUnlocked)
                    
                    if !biometricManager.isUnlocked {
                        Color.clear
                            .background(.ultraThinMaterial)
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.4), value: biometricManager.isUnlocked)
                        
                        VStack(spacing: 16) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                            
                            Text("Unlocking with Face ID...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.4), value: biometricManager.isUnlocked)
                    }
                }
                .task {
                    if !biometricManager.isUnlocked {
                        await biometricManager.authenticate()
                    }
                }
                .onChange(of: scenePhase) {
                    switch scenePhase {
                    case .background:
                        biometricManager.handleDidEnterBackground()
                    case .active:
                        biometricManager.handleWillEnterForeground()
                    default:
                        break
                    }
                }
            }
        }
    }
}
