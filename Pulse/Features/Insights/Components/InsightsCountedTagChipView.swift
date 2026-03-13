//
//  InsightsCountedTagChipView.swift
//  Pulse
//
//  Created by Codex on 3/12/26.
//

import SwiftUI

/// Read-only tag chip with an inline count badge for Insights.
struct InsightsCountedTagChipView: View {
    let text: String
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color.pulseBlue.opacity(0.85))
                .clipShape(Capsule())

            Text(text)
                .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(UIColor.systemGray5))
        .clipShape(Capsule())
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tag")
        .accessibilityValue("\(text), \(count)")
    }
}

#Preview {
    InsightsCountedTagChipView(text: "Bored", count: 3)
        .padding()
        .background(Color(.systemGroupedBackground))
}
