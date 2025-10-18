//
//  SettingsView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/27/25.
//

import SwiftUI
import UserNotifications
import Observation

struct SettingsView: View {
    // App state
    @Environment(AppLockManager.self) private var lock

    // Persisted user prefs
    @AppStorage("useBiometrics") private var useBiometrics: Bool = false
    @AppStorage("isStealthModeEnabled") private var isStealthModeEnabled: Bool = false
    @AppStorage("selectedStealthIcon") private var selectedStealthIcon: String?

    // local
    @State private var notificationsEnabled = false

    // Map AppStorage string <-> StealthIcon enum
    private var selectedIconBinding: Binding<StealthIcon> {
        Binding<StealthIcon>(
            get: {
                guard let raw = selectedStealthIcon,
                      let icon = StealthIcon(rawValue: raw) else { return .defaultIcon }
                return icon
            },
            set: { newIcon in
                selectedStealthIcon = (newIcon == .defaultIcon) ? nil : newIcon.rawValue
                StealthIconManager.set(newIcon)
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Privacy
                Section(header: Text("Privacy")) {
                    Toggle("Require Face ID", isOn: $useBiometrics)
                        .onChange(of: useBiometrics) { _, newValue in
                            // Optional behavior: if user enables Face ID and we’re currently locked, prompt now
                            if newValue && !lock.isUnlocked {
                                Task { await lock.authenticate() }
                            }
                        }

                    Toggle("Stealth Mode", isOn: $isStealthModeEnabled)

                    if isStealthModeEnabled && notificationsEnabled {
                        Text("Notifications are enabled in iOS Settings, but Pulse will not send notifications while Stealth Mode is on.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                            .accessibilityHint("Stealth Mode suppresses notifications.")
                    }
                }

                // MARK: Appearance
                Section(header: Text("Appearance")) {
                    if isStealthModeEnabled {
                        Picker("Stealth Icon", selection: selectedIconBinding) {
                            ForEach(StealthIcon.allCases, id: \.self) { icon in
                                Text(icon.readableName).tag(icon)
                            }
                        }
                    } else {
                        HStack {
                            Text("App Icon")
                            Spacer()
                            Text(selectedStealthIcon == nil ? "Default" : (selectedStealthIcon ?? "Default"))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                // MARK: Manage Data (placeholders)
                Section {
                    NavigationLink("Manage Urge Types") { Text("Coming Soon") }
                    NavigationLink("Manage Tags") { Text("Coming Soon") }
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
        .environment(AppLockManager.shared)  // Observation-style injection
}
