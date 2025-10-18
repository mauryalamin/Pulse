//
//  ContentStartupWrapper.swift
//  Pulse
//
//  Created by Maury Alamin on 5/15/25.
//

import SwiftUI
import SwiftData
import Observation

struct ContentStartupWrapper: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppLockManager.self) private var appLock   // ⬅️ Observation-style env injection

    @Query private var urges: [Urge]
    @Query private var tags: [Tag]

    var body: some View {
        HomeView()
            .task {
                if urges.isEmpty {
                    UrgeDefaults.builtIn.forEach { modelContext.insert($0) }
                }
                if tags.isEmpty {
                    TagDefaults.builtIn.forEach { modelContext.insert($0) }
                }
                if urges.isEmpty || tags.isEmpty {
                    try? modelContext.save()
                }
            }
            // MARK: - FOR TESTING PURPOSES ONLY (Remove before release)
            .task {
                await NotificationManager.shared.requestAuthorizationIfNeeded()
            }
    }
}

#Preview {
    ContentStartupWrapper()
        .environment(AppLockManager.shared)              // ⬅️ Observation: inject the instance
        .modelContainer(for: [Urge.self, Tag.self, Moment.self], inMemory: true)
}
