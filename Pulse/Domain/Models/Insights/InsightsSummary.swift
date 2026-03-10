//
//  InsightsSummary.swift
//  Pulse
//
//  Created by Codex on 3/10/26.
//

import Foundation

/// Weekly or period summary text for the Insights overview.
struct InsightsSummary: Hashable, Codable, Sendable {
    let title: String?
    let body: String
    let source: InsightTextSource
    let generatedAt: Date
}
