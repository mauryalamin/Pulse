//
//  IntensityGradientSpec.swift
//  Pulse
//
//  Created by Maury Alamin on 10/27/25.
//

import SwiftUI

enum IntensityGradientSpec {
    static let brightness: [Double]  = [0.4, 0.3, 0.2, 0.1, 0.0]
    static let saturation: [Double]  = [0.6, 0.7, 0.8, 0.9, 1.0]

    static func pair(for level: Int) -> (brightness: Double, saturation: Double) {
        let i = max(1, min(level, 5)) - 1
        return (brightness[i], saturation[i])
    }

    static func isFilled(level: Int, selected: Int?) -> Bool {
        (selected ?? 0) >= level
    }

    static func baseColor(from hex: String?, fallback: Color = .pulseBlue) -> Color {
        if let hex, let c = Color(hex: hex) { return c }
        return fallback
    }
}
