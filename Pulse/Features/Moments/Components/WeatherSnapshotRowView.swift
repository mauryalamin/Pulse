//
//  WeatherSnapshotRowView.swift
//  Pulse
//
//  Created by Maury Alamin on 11/12/25.
//

import SwiftUI

import SwiftUI

struct WeatherSnapshotRowView: View {
    let moment: Moment

    var body: some View {
        if let badge = moment.weatherBadge {
            HStack(spacing: 6) {
                Text(badge)                 // e.g., "☁️ 65°F"
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .accessibilityLabel("Weather")
            .accessibilityValue(badge)
        }
    }
}

#Preview {
    WeatherSnapshotRowView (moment: Moment(timestamp: .now, urge: Urge(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 4, gaveIn: true))
}
