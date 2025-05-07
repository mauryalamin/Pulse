//
//  Moment.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import Foundation
import SwiftData

@Model
class Moment {
    var timestamp: Date
    var vice: Vice
    var intensity: Int
    var gaveIn: Bool
    // Add Tags
    var note: String?
    
    init(timestamp: Date = .now, vice: Vice, intensity: Int, gaveIn: Bool, note: String? = nil) {
        self.timestamp = timestamp
        self.vice = vice
        self.intensity = intensity
        self.gaveIn = gaveIn
        self.note = note
    }
    
}
