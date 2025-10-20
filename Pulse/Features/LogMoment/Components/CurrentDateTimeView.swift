//
//  CurrentDateTimeView.swift
//  Pulse
//
//  Created by Maury Alamin on 10/20/25.
//

import SwiftUI

struct CurrentDateTimeView: View {
    var body: some View {
        TimelineView(.everyMinute) { context in
            let now = context.date
            let formatted = PulseDateFormatting.contextTimestamp(now)
            Text(formatted)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityLabel("Current date and time")
                .accessibilityValue(formatted)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        Text("Around This Moment")
            .font(.headline)
        CurrentDateTimeView()
    }
    .padding()
}
