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
            if let timePattern, let primary = primaryBucket(from: timePattern) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(primary.label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(percentText(primary.percentage))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .foregroundStyle(.pulseBlue)
                    }

                    timeBar(value: primary.percentage, height: 8, tint: .pulseBlue.opacity(0.85))

                    HStack(alignment: .top, spacing: 14) {
                        ForEach(remainingBuckets(from: timePattern, primary: primary), id: \.bucket) { bucket in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(bucket.label)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)

                                timeBar(value: bucket.percentage, height: 4, tint: .pulseBlue.opacity(0.45))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
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

    private func primaryBucket(from pattern: TimePatternSummary) -> TimeBucketInsight? {
        pattern.primaryBucket ?? pattern.buckets.max(by: { $0.count < $1.count })
    }

    /// Always ordered by time of day: Morning, Afternoon, Evening, Late Night.
    private func remainingBuckets(from pattern: TimePatternSummary, primary: TimeBucketInsight) -> [TimeBucketInsight] {
        let byBucket = Dictionary(uniqueKeysWithValues: pattern.buckets.map { ($0.bucket, $0) })

        return TimeBucket.allCases
            .filter { $0 != primary.bucket }
            .compactMap { byBucket[$0] }
    }

    private func timeBar(value: Double, height: CGFloat, tint: Color) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let clamped = max(0.0, min(1.0, value))
            let filledWidth = width * clamped

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(UIColor.systemGray5))
                Capsule()
                    .fill(tint)
                    .frame(width: max(height / 2, filledWidth))
            }
        }
        .frame(height: height)
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

#Preview("Ready") {
    InsightsTimePatternsSectionView(
        timePattern: InsightsPreviewFixtures.timePattern,
        dataState: .ready
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Insufficient") {
    InsightsTimePatternsSectionView(
        timePattern: nil,
        dataState: .insufficientData
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
