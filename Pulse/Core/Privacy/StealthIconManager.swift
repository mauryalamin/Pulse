//
//  StealthIconManager.swift
//  Pulse
//
//  Created by Maury Alamin on 10/17/25.
//

import UIKit

enum StealthIcon: String, CaseIterable, Sendable {
    case defaultIcon = "AppIcon"
    case stealthBlue = "AppIcon-Blue"
    case stealthGreen = "AppIcon-Green"
    case stealthClay = "AppIcon-Clay"
    case stealthLavender = "AppIcon-Lavender"
    case stealthGray = "AppIcon-Gray"
    case stealthMinimal = "AppIcon-Minimal"

    var readableName: String { rawValue.replacingOccurrences(of: "AppIcon-", with: "") }
}

enum StealthIconManager {
    static func set(_ icon: StealthIcon) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(icon == .defaultIcon ? nil : icon.rawValue)
    }
}
