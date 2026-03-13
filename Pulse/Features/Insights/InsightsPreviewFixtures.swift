//
//  InsightsPreviewFixtures.swift
//  Pulse
//
//  Created by Codex on 3/12/26.
//

import Foundation

enum InsightsPreviewFixtures {
    static let now = Date.now

    static let summary = InsightsSummary(
        title: "Last 7 Days Summary",
        body: "You logged 16 moments this week and stayed present in 75% of them.",
        source: .template,
        generatedAt: now
    )

    static let factoids: [InsightFactoid] = [
        InsightFactoid(kind: .momentsLogged, title: "Moments Logged", valueText: "16", priority: 1, isEligible: true),
        InsightFactoid(kind: .stayedPresentRate, title: "Stayed Present Rate", valueText: "75%", priority: 2, isEligible: true),
        InsightFactoid(kind: .averageIntensity, title: "Average Intensity", valueText: "3.1/5", priority: 3, isEligible: true),
        InsightFactoid(kind: .topTag, title: "Top Tag", valueText: "After Work", subtitle: "6 uses", priority: 4, isEligible: true)
    ]

    static let activitySeries: [ActivityDataPoint] = [
        ActivityDataPoint(date: now.addingTimeInterval(-6 * 86_400), label: "Mon", count: 2),
        ActivityDataPoint(date: now.addingTimeInterval(-5 * 86_400), label: "Tue", count: 1),
        ActivityDataPoint(date: now.addingTimeInterval(-4 * 86_400), label: "Wed", count: 3),
        ActivityDataPoint(date: now.addingTimeInterval(-3 * 86_400), label: "Thu", count: 2),
        ActivityDataPoint(date: now.addingTimeInterval(-2 * 86_400), label: "Fri", count: 4),
        ActivityDataPoint(date: now.addingTimeInterval(-1 * 86_400), label: "Sat", count: 3),
        ActivityDataPoint(date: now, label: "Sun", count: 1)
    ]

    static let timePattern = TimePatternSummary(
        buckets: [
            TimeBucketInsight(bucket: .morning, label: "Morning", count: 2, percentage: 0.125),
            TimeBucketInsight(bucket: .afternoon, label: "Afternoon", count: 5, percentage: 0.3125),
            TimeBucketInsight(bucket: .evening, label: "Evening", count: 7, percentage: 0.4375),
            TimeBucketInsight(bucket: .lateNight, label: "Late Night", count: 2, percentage: 0.125)
        ],
        primaryBucket: TimeBucketInsight(bucket: .evening, label: "Evening", count: 7, percentage: 0.4375)
    )

    static let observations: [InsightObservation] = [
        InsightObservation(
            title: "Evening + Stress Tags",
            body: "Most moments clustered in the evening, and stress-related tags showed up frequently.",
            source: .template,
            signalKinds: [.timeOfDay, .tag],
            priority: 1,
            generatedAt: now
        ),
        InsightObservation(
            title: "Weekend Response",
            body: "Stayed Present rate was slightly lower on weekends than weekdays.",
            source: .template,
            signalKinds: [.weekdayWeekend, .responsePattern],
            priority: 2,
            generatedAt: now
        )
    ]

    static let topTags: [TagInsight] = [
        TagInsight(name: "After Work", count: 6),
        TagInsight(name: "Stress", count: 4),
        TagInsight(name: "Alone", count: 3)
    ]

    static let urgeBreakdown: [UrgeBreakdownItem] = [
        UrgeBreakdownItem(urgeName: "Alcohol", count: 7, percentage: 0.4375),
        UrgeBreakdownItem(urgeName: "Cannabis", count: 5, percentage: 0.3125),
        UrgeBreakdownItem(urgeName: "Gambling", count: 4, percentage: 0.25)
    ]
}
