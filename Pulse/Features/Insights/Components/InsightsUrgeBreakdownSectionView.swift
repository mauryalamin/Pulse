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

    private var maxCount: Int {
        max(urgeBreakdown.map(\.count).max() ?? 0, 1)
    }

    var body: some View {
        InsightsSectionCard(title: "Urge Breakdown") {
            if urgeBreakdown.isEmpty {
                Text(fallbackCopy)
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(urgeBreakdown) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.urgeName)
                                    .font(.body)
                                Spacer()
                                Text("\(percentText(item.percentage)) • \(item.count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }

                            ProgressView(value: Double(item.count), total: Double(maxCount))
                                .tint(.orange)
                        }
                    }
                }
            }
        }
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
