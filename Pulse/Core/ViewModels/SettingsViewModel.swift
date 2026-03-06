//
//  SettingsViewModel.swift
//  Pulse
//
//  Created by Maury Alamin on 10/17/25.
//

import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    // Backed by AppStorage in the view, but VM can reflect/compute behavior
    var requireFaceID: Bool = true

    @ObservationIgnored private let appLock: AppLockManager

    init(appLock: AppLockManager) {
        self.appLock = appLock
    }

    func applyPrivacyChanges() {
        // No-ops for now; wiring points for future policies
        if !requireFaceID {
            Task { await appLock.authenticate() }   // use existing method
        }
    }
}
