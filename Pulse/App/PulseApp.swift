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

    // 🔒 Explicit persistent container (no in-memory)
    private let container: ModelContainer = {
        // Build an App Support path: .../Application Support/Pulse/Pulse.store
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Pulse", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("Pulse.store")

        let config = ModelConfiguration(url: url)
        return try! ModelContainer(for: Moment.self, Urge.self, Tag.self, configurations: config)
    }()

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
                            Color.clear.background(.ultraThinMaterial).ignoresSafeArea()
                            VStack(spacing: 16) {
                                Image(systemName: "lock.fill").font(.system(size: 32)).foregroundStyle(.secondary)
                                Text("Unlocking with Face ID...").font(.subheadline).foregroundStyle(.secondary)
                            }
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.4), value: lock.isUnlocked)
                        }
                    }
                    .task {
                        if !lock.isUnlocked { await lock.authenticate() }
                    }
                    .onChange(of: scenePhase) {
                        switch scenePhase {
                        case .background: lock.handleDidEnterBackground()
                        case .active:     lock.handleWillEnterForeground()
                        default:          break
                        }
                    }
                }
            }
            .modelContainer(container)
            .task {
                // URL is non-optional on iOS 26
                let path = container.configurations.first?.url.path ?? "<unknown>"
                print("📦 SwiftData persistent store:", path)
            }
        }
    }
}
