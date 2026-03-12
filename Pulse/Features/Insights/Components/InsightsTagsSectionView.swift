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

    var body: some View {
        InsightsSectionCard(title: "Top Tags / Common Contexts") {
            if topTags.isEmpty {
                Text(fallbackCopy)
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(topTags) { tag in
                        HStack {
                            Text(tag.name)
                                .font(.body)
                            Spacer()
                            Text("\(tag.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                                .foregroundStyle(.secondary)
                        }
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
