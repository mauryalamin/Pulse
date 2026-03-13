//
//  InsightsSummarySectionView.swift
//  Pulse
//
//  Created by Codex on 3/12/26.
//

import SwiftUI

struct InsightsSummarySectionView: View {
    let summary: InsightsSummary?
    let dataState: InsightsDataState

    var body: some View {
        InsightsSectionCard(title: "Weekly Summary") {
            if let summary {
                VStack(alignment: .leading, spacing: 8) {
                    if let title = summary.title, !title.isEmpty {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    Text(summary.body)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text(fallbackCopy)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var fallbackCopy: String {
        switch dataState {
        case .empty:
            return "No summary yet. Start logging moments to build your first weekly insight."
        case .insufficientData:
            return "A summary will appear once there is enough data for stable patterns."
        case .ready:
            return "Summary is currently unavailable."
        case .locked:
            return "Summary is locked."
        }
    }
}

#Preview("Ready") {
    InsightsSummarySectionView(
        summary: InsightsPreviewFixtures.summary,
        dataState: .ready
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty") {
    InsightsSummarySectionView(
        summary: nil,
        dataState: .empty
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
