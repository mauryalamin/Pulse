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

    @Environment(\.scenePhase) private var scenePhase
    @State private var lock = AppLockManager.shared

    // Build a single, file-backed SwiftData container for the whole app.
    // This guarantees persistence for both “Run from Xcode” and “launch from Home Screen”.
    private static let sharedContainer: ModelContainer = {
        do {
            // ~/Library/Application Support/Pulse.store
            let base = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

            let url = base.appendingPathComponent("Pulse.store", conformingTo: .database)
            let config = ModelConfiguration(url: url)

            let container = try ModelContainer(
                for: Moment.self, Urge.self, Tag.self,
                configurations: config
            )

            // One-time log so you can confirm location in Xcode console
            print("📦 SwiftData store URL:", url.path)

            return container
        } catch {
            // If anything goes wrong, fail loudly in DEBUG so we don’t silently fall back to memory
            assertionFailure("Failed to create SwiftData container: \(error)")
            // Last-resort fallback to an in-memory container so the app still runs in Development
            let fallback = try! ModelContainer(
                for: Moment.self, Urge.self, Tag.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            print("⚠️ Using IN-MEMORY SwiftData store as a fallback.")
            return fallback
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if isOnboarding {
                    OnboardingFlowView()
                } else {
                    ZStack {
                        ContentStartupWrapper()
                            .blur(radius: lock.shouldLockUI ? 30 : 0)
                            .animation(.easeInOut(duration: 0.4), value: lock.shouldLockUI)

                        if lock.shouldLockUI {
                            Color.clear
                                .background(.ultraThinMaterial)
                                .ignoresSafeArea()
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.4), value: lock.shouldLockUI)

                            VStack(spacing: 16) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.secondary)
                                Text("Unlocking with Face ID...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.4), value: lock.shouldLockUI)
                        }
                    }
                    .task {
                        if lock.shouldLockUI { await lock.authenticate() }
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
            .environment(lock)
        }
        // ✅ Inject the explicit, file-backed container for the whole app
        .modelContainer(Persistence.shared)
    }
}
