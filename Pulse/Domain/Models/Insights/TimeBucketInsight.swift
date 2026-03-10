//
//  TimeBucketInsight.swift
//  Pulse
//
//  Created by Codex on 3/10/26.
//

import Foundation

/// One bucketed time-of-day slice used in time pattern summaries.
struct TimeBucketInsight: Hashable, Codable, Sendable {
    let bucket: TimeBucket
    let label: String
    let count: Int
    /// Value from 0.0 to 1.0.
    let percentage: Double
}
