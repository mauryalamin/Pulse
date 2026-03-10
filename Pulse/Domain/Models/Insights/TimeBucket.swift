//
//  TimeBucket.swift
//  Pulse
//
//  Created by Codex on 3/10/26.
//

import Foundation

/// Time-of-day buckets used across insights.
enum TimeBucket: String, CaseIterable, Hashable, Codable, Sendable {
    case morning
    case afternoon
    case evening
    case lateNight
}
