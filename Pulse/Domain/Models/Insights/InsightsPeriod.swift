//
//  InsightsPeriod.swift
//  Pulse
//
//  Created by Codex on 3/10/26.
//

import Foundation

/// Represents the date window used to summarize moment activity.
struct InsightsPeriod: Identifiable, Hashable, Codable, Sendable {
    enum Kind: String, Hashable, Codable, Sendable {
        case last7Days
        case last30Days
        case custom
    }

    let id: String
    let label: String
    let startDate: Date
    let endDate: Date
    let kind: Kind

    init(
        id: String? = nil,
        label: String,
        startDate: Date,
        endDate: Date,
        kind: Kind
    ) {
        self.id = id ?? "\(kind.rawValue)-\(Int(startDate.timeIntervalSince1970))-\(Int(endDate.timeIntervalSince1970))"
        self.label = label
        self.startDate = startDate
        self.endDate = endDate
        self.kind = kind
    }
}
