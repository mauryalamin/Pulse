//
//  InsightsTeaserFactoidItem.swift
//  Pulse
//
//  Created by Codex on 3/11/26.
//

import Foundation

/// Lightweight display model for the By the Numbers teaser.
struct InsightsTeaserFactoidItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let valueText: String
    let subtitle: String?
    let systemImageName: String

    init(
        id: UUID = UUID(),
        title: String,
        valueText: String,
        subtitle: String? = nil,
        systemImageName: String
    ) {
        self.id = id
        self.title = title
        self.valueText = valueText
        self.subtitle = subtitle
        self.systemImageName = systemImageName
    }
}
