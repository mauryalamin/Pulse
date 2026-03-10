//
//  UrgeBreakdownItem.swift
//  Pulse
//
//  Created by Codex on 3/10/26.
//

import Foundation

/// Urge distribution for the selected period.
struct UrgeBreakdownItem: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let urgeName: String
    let count: Int
    /// Value from 0.0 to 1.0.
    let percentage: Double

    init(id: UUID = UUID(), urgeName: String, count: Int, percentage: Double) {
        self.id = id
        self.urgeName = urgeName
        self.count = count
        self.percentage = percentage
    }
}
