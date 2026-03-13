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
    private let chartHeight: CGFloat = 110

    private let orderedWeekdays: [(index: Int, label: String)] = [
        (1, "SUN"),
        (2, "MON"),
        (3, "TUE"),
        (4, "WED"),
        (5, "THU"),
        (6, "FRI"),
        (7, "SAT")
    ]

    private var weekdayCounts: [(index: Int, label: String, count: Int)] {
        let calendar = Calendar.current
        var countByWeekday: [Int: Int] = [:]

        for point in activitySeries {
            let weekday = calendar.component(.weekday, from: point.date)
            countByWeekday[weekday, default: 0] += point.count
        }

        return orderedWeekdays.map { day in
            (index: day.index, label: day.label, count: countByWeekday[day.index, default: 0])
        }
    }

    private var maxCount: Int {
        max(weekdayCounts.map(\.count).max() ?? 0, 1)
    }

    var body: some View {
        InsightsSectionCard(title: "Activity") {
            if activitySeries.isEmpty {
                Text(fallbackCopy)
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(weekdayCounts, id: \.index) { day in
                        VStack(spacing: 10) {
                            ZStack(alignment: .bottom) {
                                barView(for: day.count)
                            }
                            .frame(height: chartHeight)

                            Text(day.label)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func barView(for count: Int) -> some View {
        let height = barHeight(for: count)

        if count == 0 {
            VStack(spacing: 10) {
                Text("0")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)

                Capsule()
                    .fill(Color.pulseBlue.opacity(0.9))
                    .frame(height: 8)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        } else {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.pulseBlue.opacity(0.9))
                .frame(height: height)
                .overlay(alignment: .bottom) {
                    Text("\(count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                        .padding(.bottom, 3)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    private func barHeight(for count: Int) -> CGFloat {
        guard count > 0 else { return 8 }

        let ratio = Double(count) / Double(maxCount)
        return max(24, (chartHeight - 8) * ratio)
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
