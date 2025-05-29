//
//  SettingsView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/27/25.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("useBiometrics") private var useBiometrics: Bool = false
    @AppStorage("isStealthModeEnabled") private var isStealthModeEnabled: Bool = false
    @AppStorage("selectedStealthIcon") private var selectedStealthIcon: String?
    
    @State private var notificationsEnabled: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Privacy")) {
                    Toggle("Require Face ID", isOn: $useBiometrics)
                    Toggle("Stealth Mode", isOn: $isStealthModeEnabled)
                    if isStealthModeEnabled && notificationsEnabled {
                        Text("Notifications are enabled in iOS Settings, but Pulse will not send notifications while Stealth Mode is on.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
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
            .task {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
