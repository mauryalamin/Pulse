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
    var urge: Urge
    var intensity: Int
    var gaveIn: Bool
    var note: String?
    
    @Relationship(deleteRule: .nullify, inverse: \Tag.moments)
    var tags: [Tag]?
    
    var locationDescription: String?   // e.g. “Chicago” or “Home”
    var latitude: Double?
    var longitude: Double?
    
    init(timestamp: Date, urge: Urge, intensity: Int, gaveIn: Bool, note: String? = nil, tags: [Tag]? = nil, locationDescription: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.timestamp = timestamp
        self.urge = urge
        self.intensity = intensity
        self.gaveIn = gaveIn
        self.note = note
        self.tags = tags
        self.locationDescription = locationDescription
        self.latitude = latitude
        self.longitude = longitude
    }
}
