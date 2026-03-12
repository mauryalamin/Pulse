//
//  InsightsView.swift
//  Pulse
//
//  Created by Codex on 3/12/26.
//

import SwiftUI

struct InsightsView: View {
    let snapshot: InsightsSnapshot

    var body: some View {
        ZStack {
            Color(.grayBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    switch snapshot.dataState {
                    case .locked:
                        lockedShell
                    case .empty:
                        stateBanner(
                            title: "Insights Are Waiting For Your First Data",
                            body: "Log a few moments and this screen will fill in with trends and patterns."
                        )
                        contentSections
                    case .insufficientData:
                        stateBanner(
                            title: "Keep Logging To Unlock Stronger Patterns",
                            body: "You already have data. Add a few more moments to improve reliability across sections."
                        )
                        contentSections
                    case .ready:
                        contentSections
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Insights")
    }

    private var contentSections: some View {
        VStack(spacing: 12) {
            InsightsSummarySectionView(summary: snapshot.summary, dataState: snapshot.dataState)
            InsightsByTheNumbersSectionView(factoids: snapshot.factoids, dataState: snapshot.dataState)
            InsightsActivitySectionView(activitySeries: snapshot.activitySeries, dataState: snapshot.dataState)
            InsightsTimePatternsSectionView(timePattern: snapshot.timePattern, dataState: snapshot.dataState)
            InsightsObservationsSectionView(observations: snapshot.observations, dataState: snapshot.dataState)
            InsightsTagsSectionView(topTags: snapshot.topTags, dataState: snapshot.dataState)
            InsightsUrgeBreakdownSectionView(urgeBreakdown: snapshot.urgeBreakdown, dataState: snapshot.dataState)
        }
    }

    private var lockedShell: some View {
        VStack(spacing: 12) {
            InsightsSectionCard(title: "Insights") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Premium Feature", systemImage: "lock.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Unlock full insights to view your summary, patterns, and breakdowns.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.gray.opacity(0.15))
                    .frame(height: 92)
                    .overlay(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 8) {
                            Capsule().fill(.secondary.opacity(0.3)).frame(width: 130, height: 8)
                            Capsule().fill(.secondary.opacity(0.2)).frame(width: 200, height: 8)
                            Capsule().fill(.secondary.opacity(0.2)).frame(width: 160, height: 8)
                        }
                        .padding(14)
                    }
            }
        }
    }

    private func stateBanner(title: String, body: String) -> some View {
        InsightsSectionCard(title: "Insights Status") {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Ready") {
    InsightsView(snapshot: .previewReady)
}

#Preview("Empty") {
    InsightsView(snapshot: .previewEmpty)
}

#Preview("Insufficient") {
    InsightsView(snapshot: .previewInsufficient)
}

#Preview("Locked") {
    InsightsView(snapshot: .previewLocked)
}

private extension InsightsSnapshot {
    static var previewReady: InsightsSnapshot {
        let now = Date.now
        let period = InsightsPeriod(
            label: "Last 7 Days",
            startDate: now.addingTimeInterval(-6 * 86_400),
            endDate: now,
            kind: .last7Days
        )

        return InsightsSnapshot(
            period: period,
            summary: InsightsSummary(
                title: "Last 7 Days Summary",
                body: "You logged 16 moments this week and stayed present in 75% of them.",
                source: .template,
                generatedAt: now
            ),
            factoids: [
                InsightFactoid(kind: .momentsLogged, title: "Moments Logged", valueText: "16", priority: 1, isEligible: true),
                InsightFactoid(kind: .stayedPresentRate, title: "Stayed Present Rate", valueText: "75%", priority: 2, isEligible: true),
                InsightFactoid(kind: .averageIntensity, title: "Average Intensity", valueText: "3.1/5", priority: 3, isEligible: true),
                InsightFactoid(kind: .mostCommonUrge, title: "Most Common Urge", valueText: "Alcohol", subtitle: "7 moments", priority: 4, isEligible: true)
            ],
            activitySeries: [
                ActivityDataPoint(date: now.addingTimeInterval(-6 * 86_400), label: "Mon", count: 2),
                ActivityDataPoint(date: now.addingTimeInterval(-5 * 86_400), label: "Tue", count: 1),
                ActivityDataPoint(date: now.addingTimeInterval(-4 * 86_400), label: "Wed", count: 3),
                ActivityDataPoint(date: now.addingTimeInterval(-3 * 86_400), label: "Thu", count: 2),
                ActivityDataPoint(date: now.addingTimeInterval(-2 * 86_400), label: "Fri", count: 4),
                ActivityDataPoint(date: now.addingTimeInterval(-1 * 86_400), label: "Sat", count: 3),
                ActivityDataPoint(date: now, label: "Sun", count: 1)
            ],
            timePattern: TimePatternSummary(
                buckets: [
                    TimeBucketInsight(bucket: .morning, label: "Morning", count: 2, percentage: 0.125),
                    TimeBucketInsight(bucket: .afternoon, label: "Afternoon", count: 5, percentage: 0.3125),
                    TimeBucketInsight(bucket: .evening, label: "Evening", count: 7, percentage: 0.4375),
                    TimeBucketInsight(bucket: .lateNight, label: "Late Night", count: 2, percentage: 0.125)
                ],
                primaryBucket: TimeBucketInsight(bucket: .evening, label: "Evening", count: 7, percentage: 0.4375)
            ),
            observations: [
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
            ],
            topTags: [
                TagInsight(name: "After Work", count: 6),
                TagInsight(name: "Stress", count: 4),
                TagInsight(name: "Alone", count: 3)
            ],
            urgeBreakdown: [
                UrgeBreakdownItem(urgeName: "Alcohol", count: 7, percentage: 0.4375),
                UrgeBreakdownItem(urgeName: "Cannabis", count: 5, percentage: 0.3125),
                UrgeBreakdownItem(urgeName: "Gambling", count: 4, percentage: 0.25)
            ],
            dataState: .ready,
            lastRefreshedAt: now
        )
    }

    static var previewEmpty: InsightsSnapshot {
        let now = Date.now
        return InsightsSnapshot(
            period: InsightsPeriod(label: "Last 7 Days", startDate: now.addingTimeInterval(-6 * 86_400), endDate: now, kind: .last7Days),
            summary: nil,
            factoids: [],
            activitySeries: [],
            timePattern: nil,
            observations: [],
            topTags: [],
            urgeBreakdown: [],
            dataState: .empty,
            lastRefreshedAt: now
        )
    }

    static var previewInsufficient: InsightsSnapshot {
        let now = Date.now
        return InsightsSnapshot(
            period: InsightsPeriod(label: "Last 7 Days", startDate: now.addingTimeInterval(-6 * 86_400), endDate: now, kind: .last7Days),
            summary: InsightsSummary(
                title: "Last 7 Days Summary",
                body: "Only a few moments are available so far.",
                source: .template,
                generatedAt: now
            ),
            factoids: [
                InsightFactoid(kind: .momentsLogged, title: "Moments Logged", valueText: "2", priority: 1, isEligible: true)
            ],
            activitySeries: [
                ActivityDataPoint(date: now.addingTimeInterval(-86_400), label: "Sat", count: 1),
                ActivityDataPoint(date: now, label: "Sun", count: 1)
            ],
            timePattern: nil,
            observations: [],
            topTags: [],
            urgeBreakdown: [],
            dataState: .insufficientData,
            lastRefreshedAt: now
        )
    }

    static var previewLocked: InsightsSnapshot {
        let now = Date.now
        return InsightsSnapshot(
            period: InsightsPeriod(label: "Last 7 Days", startDate: now.addingTimeInterval(-6 * 86_400), endDate: now, kind: .last7Days),
            summary: nil,
            factoids: [],
            activitySeries: [],
            timePattern: nil,
            observations: [],
            topTags: [],
            urgeBreakdown: [],
            dataState: .locked,
            lastRefreshedAt: now
        )
    }
}
