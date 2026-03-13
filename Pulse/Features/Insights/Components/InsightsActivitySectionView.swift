//
//  InsightsActivitySectionView.swift
//  Pulse
//
//  Created by Codex on 3/12/26.
//

import SwiftUI

struct InsightsActivitySectionView: View {
    let activitySeries: [ActivityDataPoint]
    let dataState: InsightsDataState

    private var maxCount: Int {
        max(activitySeries.map(\.count).max() ?? 0, 1)
    }

    var body: some View {
        InsightsSectionCard(title: "Activity") {
            if activitySeries.isEmpty {
                Text(fallbackCopy)
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(activitySeries) { point in
                        HStack(spacing: 8) {
                            Text(point.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 34, alignment: .leading)

                            ProgressView(value: Double(point.count), total: Double(maxCount))
                                .tint(.pulseBlue)

                            Text("\(point.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                                .frame(width: 22, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    private var fallbackCopy: String {
        switch dataState {
        case .empty:
            return "Activity will appear once moments are logged."
        case .insufficientData:
            return "Activity trend is limited with current data."
        case .ready:
            return "No activity points are available."
        case .locked:
            return "Activity is locked."
        }
    }
}

#Preview("Ready") {
    InsightsActivitySectionView(
        activitySeries: InsightsPreviewFixtures.activitySeries,
        dataState: .ready
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty") {
    InsightsActivitySectionView(
        activitySeries: [],
        dataState: .empty
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
