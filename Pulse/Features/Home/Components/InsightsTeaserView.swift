//
//  InsightsTeaserView.swift
//  Pulse
//
//  Created by Codex on 3/11/26.
//

import SwiftUI

/// Compact "By the Numbers" teaser module for the Moments screen.
struct InsightsTeaserView: View {
    let snapshot: InsightsSnapshot
    let onTap: (() -> Void)?

    init(snapshot: InsightsSnapshot, onTap: (() -> Void)? = nil) {
        self.snapshot = snapshot
        self.onTap = onTap
    }

    private var items: [InsightsTeaserFactoidItem] {
        snapshot.factoids
            .filter(\.isEligible)
            .sorted { lhs, rhs in
                if lhs.priority == rhs.priority {
                    return lhs.kind.rawValue < rhs.kind.rawValue
                }
                return lhs.priority < rhs.priority
            }
            .prefix(3)
            .map { factoid in
                InsightsTeaserFactoidItem(
                    title: factoid.title,
                    valueText: factoid.valueText,
                    subtitle: factoid.subtitle,
                    systemImageName: iconName(for: factoid.kind)
                )
            }
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                header
                content
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.interactive(onTap != nil), in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var header: some View {
        HStack(spacing: 8) {
            Text("BY THE NUMBERS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Spacer()

            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch snapshot.dataState {
        case .ready:
            readyContent
        case .empty:
            placeholderContent(
                title: "No moments in this period yet",
                subtitle: "Log a few moments to start seeing insights."
            )
        case .insufficientData:
            placeholderContent(
                title: "Not enough data yet",
                subtitle: "Keep logging moments to unlock stronger patterns."
            )
        case .locked:
            placeholderContent(
                title: "Insights locked",
                subtitle: "By the Numbers is available in premium Insights.",
                iconName: "lock.fill"
            )
        }
    }

    private var readyContent: some View {
        HStack(spacing: 10) {
            if items.isEmpty {
                placeholderContent(
                    title: "Patterns are preparing",
                    subtitle: "Insights are refreshing for this period."
                )
            } else {
                ForEach(items) { item in
                    teaserCell(item)
                }

                if items.count < 3 {
                    ForEach(0..<(3 - items.count), id: \.self) { _ in
                        placeholderMiniCell
                    }
                }
            }
        }
    }

    private var placeholderRow: some View {
        HStack(spacing: 10) {
            placeholderMiniCell
            placeholderMiniCell
            placeholderMiniCell
        }
    }

    private var placeholderMiniCell: some View {
        VStack(alignment: .leading, spacing: 6) {
            Capsule()
                .fill(.secondary.opacity(0.2))
                .frame(width: 42, height: 7)
            Capsule()
                .fill(.secondary.opacity(0.2))
                .frame(width: 70, height: 7)
        }
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
        .padding(8)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func teaserCell(_ item: InsightsTeaserFactoidItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: item.systemImageName)
                    .font(.caption)
                Text(item.valueText)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text(item.title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if let subtitle = item.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func placeholderContent(title: String, subtitle: String, iconName: String = "chart.bar.fill") -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func iconName(for kind: InsightFactoidKind) -> String {
        switch kind {
        case .momentsLogged: "list.bullet"
        case .stayedPresentRate: "percent"
        case .stayedPresentCount: "checkmark.seal"
        case .averageIntensity: "exclamationmark.2"
        case .mostCommonTimeWindow: "clock"
        case .mostCommonUrge: "bolt.heart"
        case .topTag: "tag"
        case .changeVsLastWeek: "chart.line.uptrend.xyaxis"
        case .mostActiveDay: "calendar"
        case .commonLocationType: "mappin.and.ellipse"
        case .highestIntensityPeriod: "flame"
        }
    }
}

#Preview("Ready") {
    let now = Date.now
    let period = InsightsPeriod(
        label: "Last 7 Days",
        startDate: now.addingTimeInterval(-6 * 86_400),
        endDate: now,
        kind: .last7Days
    )

    let snapshot = InsightsSnapshot(
        period: period,
        summary: InsightsSummary(
            title: "Last 7 Days Summary",
            body: "Placeholder summary",
            source: .template,
            generatedAt: now
        ),
        factoids: [
            InsightFactoid(kind: .momentsLogged, title: "Moments", valueText: "24", priority: 1, isEligible: true),
            InsightFactoid(kind: .stayedPresentCount, title: "Stayed Present", valueText: "18", priority: 2, isEligible: true),
            InsightFactoid(kind: .averageIntensity, title: "Avg Intensity", valueText: "3.2/5", priority: 3, isEligible: true)
        ],
        activitySeries: [],
        timePattern: nil,
        observations: [],
        topTags: [],
        urgeBreakdown: [],
        dataState: .ready,
        lastRefreshedAt: now
    )

    return InsightsTeaserView(snapshot: snapshot)
        .padding()
        .background(Color(.systemGroupedBackground))
}
