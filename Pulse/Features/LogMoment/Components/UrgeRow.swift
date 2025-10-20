//
//  UrgeRow.swift
//  Pulse
//
//  Created by Maury Alamin on 10/20/25.
//

import SwiftUI

struct UrgeRow: View {
    let name: String
    let colorHex: String
    let isSelected: Bool

    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 14

    var body: some View {
        HStack(spacing: 8) {
            let swatch = Color(hex: colorHex) ?? .gray

            Circle()
                .fill(swatch)
                .frame(width: circleSize, height: circleSize)
                .overlay(Circle().stroke(.secondary.opacity(0.25), lineWidth: 1))

            Text(name)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 8)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 6)           // comfy tap target
        .contentShape(Rectangle())       // tap anywhere in row
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name)\(isSelected ? ", selected" : "")")
        .accessibilityHint("Select urge")
    }
}

#Preview {
    UrgeRow(name: "Cannabis", colorHex: "#FFFFFF", isSelected: false)
}
