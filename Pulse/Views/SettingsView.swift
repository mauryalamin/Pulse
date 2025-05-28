//
//  SettingsView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/27/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("useBiometrics") private var useBiometrics: Bool = false
    @AppStorage("isStealthModeEnabled") private var isStealthModeEnabled: Bool = false
    @AppStorage("selectedStealthIcon") private var selectedStealthIcon: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Privacy")) {
                    Toggle("Require Face ID", isOn: $useBiometrics)
                    Toggle("Stealth Mode", isOn: $isStealthModeEnabled)
                }

                Section(header: Text("Appearance")) {
                    if let icon = selectedStealthIcon {
                        HStack {
                            Text("Selected Icon")
                            Spacer()
                            Text(icon)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("Default icon in use")
                            .foregroundStyle(.secondary)
                    }
                }

                // Placeholder for future features
                Section {
                    NavigationLink("Manage Urge Types") {
                        Text("Coming Soon")
                    }
                    NavigationLink("Manage Tags") {
                        Text("Coming Soon")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
