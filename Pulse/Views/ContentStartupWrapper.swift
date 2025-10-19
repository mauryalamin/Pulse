//
//  ContentStartupWrapper.swift
//  Pulse
//
//  Created by Maury Alamin on 5/15/25.
//

import SwiftUI
import SwiftData

struct ContentStartupWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var urges: [Urge]
    @Query private var tags: [Tag]

    var body: some View {
        HomeView()
            .task {
                seedDefaultsIfNeeded()  // no await
                if !isRunningInPreview {
                    await NotificationManager.shared.requestAuthorizationIfNeeded()
                }
            }
    }

    @MainActor
    private func seedDefaultsIfNeeded() {
        var didInsert = false
        if urges.isEmpty {
            UrgeDefaults.builtIn.forEach { modelContext.insert($0) }
            didInsert = true
        }
        if tags.isEmpty {
            TagDefaults.builtIn.forEach { modelContext.insert($0) }
            didInsert = true
        }
        if didInsert { try? modelContext.save() }
    }

    private var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

#Preview {
    ContentStartupWrapper()
        .environment(AppLockManager.shared)              // ⬅️ Observation: inject the instance
        .modelContainer(for: [Urge.self, Tag.self, Moment.self], inMemory: true)
}
