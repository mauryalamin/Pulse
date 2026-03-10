//
//  TagInsight.swift
//  Pulse
//
//  Created by Codex on 3/10/26.
//

import Foundation

/// Top tags by moment usage within the selected period.
struct TagInsight: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let name: String
    let count: Int

    init(id: UUID = UUID(), name: String, count: Int) {
        self.id = id
        self.name = name
        self.count = count
    }
}
