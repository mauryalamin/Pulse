//
//  InsightsSupportingEnums.swift
//  Pulse
//
//  Created by Codex on 3/10/26.
//

import Foundation

/// Availability state for an Insights payload.
enum InsightsDataState: String, CaseIterable, Hashable, Codable, Sendable {
    case empty
    case insufficientData
    case ready
    case locked
}

/// Source used for generated narrative text in Insights.
enum InsightTextSource: String, CaseIterable, Hashable, Codable, Sendable {
    case template
    case foundationModel
}
