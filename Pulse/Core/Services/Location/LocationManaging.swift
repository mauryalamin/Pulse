//
//  LocationManaging.swift
//  Pulse
//
//  Created by Maury Alamin on 10/17/25.
//

import Foundation
import CoreLocation

//public struct LocationSnapshot: Sendable {
//    public let lat: Double
//    public let lon: Double
//    public let place: String?
//    public init(lat: Double, lon: Double, place: String? = nil) {
//        self.lat = lat; self.lon = lon; self.place = place
//    }
//}
//
//public protocol LocationManaging {
//    func snapshot() async -> LocationSnapshot?
//}

protocol LocationManaging: AnyObject {
    var location: CLLocation? { get }
    var placename: String? { get }
    var authorizationStatus: CLAuthorizationStatus { get }

    func requestPermissionAndLocation()
    func refreshIfAuthorized()
    func snapshot() async -> LocationSnapshot?
}

// If you already have LocationSnapshot, keep your existing one.
// This is the minimal shape used by CreateMomentDTO, etc.
public struct LocationSnapshot: Sendable {
    public let lat: Double?
    public let lon: Double?
    public let place: String?

    public init(lat: Double?, lon: Double?, place: String?) {
        self.lat = lat
        self.lon = lon
        self.place = place
    }
}
