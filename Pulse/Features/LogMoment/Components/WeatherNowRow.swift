//
//  WeatherNowRow.swift
//  Pulse
//
//  Created by Maury Alamin on 10/22/25.
//

import SwiftUI

enum WeatherNowState: Equatable {
    case loading
    case loaded(WeatherSnapshot)
    case failed(String)   // message (not shown to user unless you want)
}

struct WeatherNowRow: View {
    let state: WeatherNowState

    var body: some View {
        HStack(spacing: 6) {
            // Icon
            Image(systemName: symbolName)
                .imageScale(.small)
                .symbolRenderingMode(.monochrome)
                .accessibilityHidden(true)

            // Text
            Text(labelText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .accessibilityLabel("Weather")
                .accessibilityValue(accessibilityValue)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Derived

    private var symbolName: String {
        switch state {
        case .loading:
            return "cloud"                 // neutral placeholder
        case .failed:
            return "exclamationmark.triangle"
        case .loaded(let snap):
            return WeatherFormatting.symbolName(for: snap.sfSymbol, code: snap.conditionCode)
        }
    }

    private var labelText: String {
        switch state {
        case .loading:
            return "Retrieving weather…"
        case .failed:
            return "Weather unavailable"
        case .loaded(let snap):
            return WeatherFormatting.formattedTempCompact(celsius: snap.temperature)  // e.g., "65°F"
        }
    }

    private var accessibilityValue: String {
        switch state {
        case .loading: return "Retrieving"
        case .failed:  return "Unavailable"
        case .loaded(let snap):
            return WeatherFormatting.formattedTempAccessibility(celsius: snap.temperature)
            // e.g., "65 degrees Fahrenheit"
        }
    }
}

#Preview("Loading") {
    WeatherNowRow(state: .loading)
        .padding()
}

#Preview("Loaded") {
    let snap = WeatherSnapshot(temperature: 18, conditionCode: 2) // partly cloudy
    WeatherNowRow(state: .loaded(snap))
        .padding()
}

#Preview("Failed") {
    WeatherNowRow(state: .failed("Network error"))
        .padding()
}
