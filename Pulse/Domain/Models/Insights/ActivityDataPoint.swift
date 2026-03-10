//
//  ActivityDataPoint.swift
//  Pulse
//
//  Created by Codex on 3/10/26.
//

import Foundation

/// One data point in the activity trend series.
struct ActivityDataPoint: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let date: Date
    let label: String
    let count: Int

    init(id: UUID = UUID(), date: Date, label: String, count: Int) {
        self.id = id
        self.date = date
        self.label = label
        self.count = count
    }
}
