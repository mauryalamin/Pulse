//
//  Haptics.swift
//  Pulse
//
//  Created by Maury Alamin on 10/27/25.
//

import Foundation
import UIKit
import CoreHaptics

enum Haptics {
    static func lightTap() {
        #if targetEnvironment(simulator)
        // Simulator: skip (prevents CHHapticPattern warnings)
        return
        #else
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.prepare()
            gen.impactOccurred()
        } else {
            // Fallback to non-haptic feedback generator (optional)
            let gen = UISelectionFeedbackGenerator()
            gen.prepare()
            gen.selectionChanged()
        }
        #endif
    }
}
