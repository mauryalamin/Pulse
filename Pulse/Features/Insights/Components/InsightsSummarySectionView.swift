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
        Group {
            if let summary {
                Text(summary.body)
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.pulseBlue)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(fallbackCopy)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
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
