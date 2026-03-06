//
//  SettingsView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/27/25.
//

import SwiftUI
import Observation

struct SettingsView: View {
    // App state
    @Environment(AppLockManager.self) private var lock

    // Persisted user prefs
    @AppStorage("useBiometrics") private var useBiometrics: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Privacy
                Section(header: Text("Privacy")) {
                    Toggle("Require Face ID", isOn: $useBiometrics)
                        .onChange(of: useBiometrics) { _, newValue in
                            if newValue {
                                Task {
                                    let enabled = await lock.requestBiometricsOptIn()
                                    if !enabled {
                                        useBiometrics = false
                                    }
                                }
                            } else {
                                lock.disableBiometrics()
                            }
                        }
                }

                // MARK: Manage Data (placeholders)
                Section {
                    NavigationLink("Manage Urge Types") { Text("Coming Soon") }
                    NavigationLink("Manage Tags") { Text("Coming Soon") }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppLockManager.shared)  // Observation-style injection
}
