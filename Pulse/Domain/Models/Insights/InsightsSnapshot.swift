//
//  InsightsSnapshot.swift
//  Pulse
//
//  Created by Codex on 3/10/26.
//

import Foundation

/// Full precomputed Insights payload consumed by future UI surfaces.
struct InsightsSnapshot: Hashable, Codable, Sendable {
    let period: InsightsPeriod
    let summary: InsightsSummary?
    let factoids: [InsightFactoid]
    let activitySeries: [ActivityDataPoint]
    let timePattern: TimePatternSummary?
    let observations: [InsightObservation]
    let topTags: [TagInsight]
    let urgeBreakdown: [UrgeBreakdownItem]
    let dataState: InsightsDataState
    let lastRefreshedAt: Date
}

