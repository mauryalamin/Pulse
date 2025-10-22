//
//  WeatherFormatting.swift
//  Pulse
//
//  Created by Maury Alamin on 10/22/25.
//

import Foundation
import CoreLocation
import SwiftUI

enum WeatherFormatting {
    // MARK: - Temp formatting

    /// "65°F" or "18°C" – always compact, always includes unit letter.
    static func formattedTempCompact(celsius: Double?) -> String {
        guard let c = celsius else { return "—°" }
        let usesF = Locale.current.usesFahrenheit
        let value = usesF ? (c * 9/5 + 32) : c
        let rounded = Int(value.rounded())
        return "\(rounded)\(usesF ? "°F" : "°C")"
    }

    /// Accessibility-friendly: "65 degrees Fahrenheit" / "18 degrees Celsius".
    static func formattedTempAccessibility(celsius: Double?) -> String {
        guard let c = celsius else { return "Temperature unavailable" }
        let usesF = Locale.current.usesFahrenheit
        let value = usesF ? (c * 9/5 + 32) : c
        let rounded = Int(value.rounded())
        return "\(rounded) degrees \(usesF ? "Fahrenheit" : "Celsius")"
    }

    /// Pick an SF Symbol for conditions (kept from earlier)
    static func symbolName(for conditionSymbol: String?, code: Int?) -> String {
        if let s = conditionSymbol, !s.isEmpty { return s }
        switch code {
        case 0:  return "sun.max.fill"
        case 1:  return "sun.min.fill"
        case 2:  return "cloud.sun.fill"
        case 3:  return "cloud.fill"
        case 45,48: return "cloud.fog.fill"
        case 51,53,55: return "cloud.drizzle.fill"
        case 61,63,65: return "cloud.rain.fill"
        case 71,73,75: return "snow"
        case 80,81,82: return "cloud.heavyrain.fill"
        default: return "cloud"
        }
    }
}

private extension Locale {
    var usesFahrenheit: Bool {
        let id = identifier.lowercased()
        return id.contains("us") || id.contains("en_us") || id.contains("liberia") || id.contains("mm")
    }
}
