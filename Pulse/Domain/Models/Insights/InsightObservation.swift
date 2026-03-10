//
//  InsightObservation.swift
//  Pulse
//
//  Created by Codex on 3/10/26.
//

import Foundation

/// A single "What Stood Out" narrative insight.
struct InsightObservation: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let title: String?
    let body: String
    let source: InsightTextSource
    let signalKinds: [ObservationSignalKind]
    /// Lower values can be treated as higher display priority.
    let priority: Int
    let generatedAt: Date

    init(
        id: UUID = UUID(),
        title: String? = nil,
        body: String,
        source: InsightTextSource,
        signalKinds: [ObservationSignalKind],
        priority: Int,
        generatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.source = source
        self.signalKinds = signalKinds
        self.priority = priority
        self.generatedAt = generatedAt
    }
}

/// Signals used to explain what evidence informed an observation.
enum ObservationSignalKind: String, CaseIterable, Hashable, Codable, Sendable {
    case timeOfDay
    case tag
    case urgeType
    case intensity
    case location
    case weather
    case weekdayWeekend
    case responsePattern
}
