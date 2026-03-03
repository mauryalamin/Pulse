//
//  EditableContextRow.swift
//  Pulse
//
//  Created by Codex on 3/3/26.
//

import SwiftUI

struct EditableContextRow: View {
    let iconName: String
    let valueText: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .imageScale(.small)
                .foregroundStyle(.secondary)

            Text(valueText)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text("Adjust")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview("Date & Time Row") {
    EditableContextRow(
        iconName: "calendar",
        valueText: Date.now.formatted(date: .long, time: .shortened)
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Weather Row") {
    EditableContextRow(
        iconName: "cloud.sun.fill",
        valueText: "72°F"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Location Row") {
    EditableContextRow(
        iconName: "mappin.circle.fill",
        valueText: "Chicago, IL"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
