//
//  SettingsViewModel.swift
//  Pulse
//
//  Created by Maury Alamin on 10/17/25.
//

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {
    // Backed by AppStorage in the view, but VM can reflect/compute behavior
    var requireFaceID: Bool = true
    var stealthMode: Bool = false
    var selectedIcon: StealthIcon = .defaultIcon

    @ObservationIgnored private let appLock: AppLockManager

    init(appLock: AppLockManager) {
        self.appLock = appLock
    }

    func applyIconChange() {
        StealthIconManager.set(selectedIcon)
    }

    func applyPrivacyChanges() {
        // No-ops for now; wiring points for future policies
        if !requireFaceID {
            Task { await appLock.authenticate() }   // use existing method
        }
    }
}
