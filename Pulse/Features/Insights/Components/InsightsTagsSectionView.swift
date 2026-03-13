//
//  InsightsTagsSectionView.swift
//  Pulse
//
//  Created by Codex on 3/12/26.
//

import SwiftUI

struct InsightsTagsSectionView: View {
    let topTags: [TagInsight]
    let dataState: InsightsDataState
    var interitemSpacing: CGFloat = 12
    var rowSpacing: CGFloat = 8

    var body: some View {
        InsightsSectionCard(title: "Top Tags / Common Contexts") {
            if topTags.isEmpty {
                Text(fallbackCopy)
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                JustifiedTagsLayout(
                    interitemSpacing: interitemSpacing,
                    rowSpacing: rowSpacing
                ) {
                    ForEach(topTags) { tag in
                        InsightsCountedTagChipView(text: tag.name, count: tag.count)
                    }
                }
            }
        }
    }

    private var fallbackCopy: String {
        switch dataState {
        case .empty:
            return "Top tags will appear after moments with tags are logged."
        case .insufficientData:
            return "Not enough tagged moments yet for strong context signals."
        case .ready:
            return "No top tags are available."
        case .locked:
            return "Top tags are locked."
        }
    }
}

#Preview("Ready") {
    InsightsTagsSectionView(
        topTags: InsightsPreviewFixtures.topTags,
        dataState: .ready
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("No Tags") {
    InsightsTagsSectionView(
        topTags: [],
        dataState: .insufficientData
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
