//
//  InsightsTimePatternsSectionView.swift
//  Pulse
//
//  Created by Codex on 3/12/26.
//

import SwiftUI

struct InsightsTimePatternsSectionView: View {
    let timePattern: TimePatternSummary?
    let dataState: InsightsDataState

    var body: some View {
        InsightsSectionCard(title: "Time Patterns") {
            if let timePattern {
                VStack(alignment: .leading, spacing: 10) {
                    if let primary = timePattern.primaryBucket {
                        Text("Most common: \(primary.label) (\(percentText(primary.percentage)))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    ForEach(timePattern.buckets, id: \.bucket) { bucket in
                        HStack {
                            Text(bucket.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(bucket.count) • \(percentText(bucket.percentage))")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }
            } else {
                Text(fallbackCopy)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func percentText(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }

    private var fallbackCopy: String {
        switch dataState {
        case .empty:
            return "Time patterns appear after moments are logged."
        case .insufficientData:
            return "More data is needed before a clear time pattern emerges."
        case .ready:
            return "No time pattern data available."
        case .locked:
            return "Time patterns are locked."
        }
    }
}
