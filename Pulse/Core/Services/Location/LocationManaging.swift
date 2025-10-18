//
//  LocationManaging.swift
//  Pulse
//
//  Created by Maury Alamin on 10/17/25.
//

import Foundation
import CoreLocation

public struct LocationSnapshot: Sendable {
    public let lat: Double
    public let lon: Double
    public let place: String?
    public init(lat: Double, lon: Double, place: String? = nil) {
        self.lat = lat; self.lon = lon; self.place = place
    }
}

public protocol LocationManaging {
    func snapshot() async -> LocationSnapshot?
}
