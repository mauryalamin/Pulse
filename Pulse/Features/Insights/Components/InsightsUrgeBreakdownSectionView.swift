//
//  InsightsUrgeBreakdownSectionView.swift
//  Pulse
//
//  Created by Codex on 3/12/26.
//

import SwiftUI

struct InsightsUrgeBreakdownSectionView: View {
    let urgeBreakdown: [UrgeBreakdownItem]
    let dataState: InsightsDataState

    var body: some View {
        InsightsSectionCard(title: "Urge Breakdown") {
            if urgeBreakdown.isEmpty {
                Text(fallbackCopy)
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(urgeBreakdown) { item in
                        HStack(alignment: .center, spacing: 12) {
                            Text(item.urgeName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .frame(width: 90, alignment: .leading)

                            urgeBar(value: item.percentage)
                        }
                    }
                }
                .padding(12)
                .background(Color(UIColor.systemGray5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func urgeBar(value: Double) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let clamped = max(0.0, min(1.0, value))
            let fillWidth = max(40, width * clamped)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.pulseBlue.opacity(0.20))

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.pulseBlue.opacity(0.85))
                    .frame(width: min(width, fillWidth))
                    .overlay(alignment: .leading) {
                        Text(percentText(clamped))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                            .padding(.leading, 10)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
            }
        }
        .frame(height: 24)
    }

    private func percentText(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }

    private var fallbackCopy: String {
        switch dataState {
        case .empty:
            return "Urge breakdown appears once moments are logged."
        case .insufficientData:
            return "More moments are needed for a clear urge distribution."
        case .ready:
            return "No urge breakdown data available."
        case .locked:
            return "Urge breakdown is locked."
        }
    }
}

#Preview("Ready") {
    InsightsUrgeBreakdownSectionView(
        urgeBreakdown: InsightsPreviewFixtures.urgeBreakdown,
        dataState: .ready
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Locked") {
    InsightsUrgeBreakdownSectionView(
        urgeBreakdown: [],
        dataState: .locked
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
