//
//  TimePatternSummary.swift
//  Pulse
//
//  Created by Codex on 3/10/26.
//

import Foundation

/// Summary of when moments happen most often.
struct TimePatternSummary: Hashable, Codable, Sendable {
    let buckets: [TimeBucketInsight]
    let primaryBucket: TimeBucketInsight?
}
