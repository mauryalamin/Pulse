//
//  LocationManager.swift
//  Pulse
//
//  Created by Maury Alamin on 5/20/25.
//

import Foundation
import CoreLocation
import MapKit
import Observation


enum LocationFormatter {
    /// Primary formatter using the fields you actually have in LogMomentView.
    /// - If `placename` exists -> return it
    /// - Else if coords exist -> "lat, lon"
    /// - Else if authorized -> "Retrieving location…"
    /// - Else -> "Location unavailable"
    static func displayName(
        placename: String?,
        lat: Double?,
        lon: Double?,
        isAuthorized: Bool
    ) -> String {
        if let name = placename, !name.isEmpty {
            return name
        }
        if let lat = lat, let lon = lon {
            return String(format: "%.3f, %.3f", lat, lon)
        }
        return isAuthorized
            ? "Retrieving your location…"
            : "Location unavailable"
    }

    // Optional: keep the old CLPlacemark-based helper if you use it elsewhere
    static func displayName(from placemark: CLPlacemark?) -> String? {
        guard let pm = placemark else { return nil }
        if let city = pm.locality, let region = pm.administrativeArea { return "\(city), \(region)" }
        if let city = pm.locality { return city }
        if let region = pm.administrativeArea { return region }
        if let country = pm.country { return country }
        return nil
    }
}

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private let manager = CLLocationManager()

    // Published/observable properties
    var location: CLLocation?
    var placename: String?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: - Permission flow
    func requestPermissionAndLocation() {
        let status = manager.authorizationStatus
        authorizationStatus = status

        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    // ✅ New helper used by preflightAuthorization()
    func requestLocation() {
        manager.requestLocation()
    }

    // ✅ New helper used by refreshIfAuthorized()
    func refreshIfAuthorized() {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocation()
        default:
            break
        }
    }

    // ✅ New helper used by preflightAuthorization()
    func preflightAuthorization() {
        switch authorizationStatus {
        case .notDetermined:
            requestPermissionAndLocation()
        default:
            break
        }
    }

    // MARK: - Delegate methods
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        location = loc
        Task {
            await reverseGeocode(loc)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager error:", error.localizedDescription)
    }

    // MARK: - Reverse Geocode
    private func reverseGeocode(_ loc: CLLocation) async {
        if let request = MKReverseGeocodingRequest(location: loc) {
            do {
                let items = try await request.mapItems
                let item = items.first
                let display =
                    item?.address?.shortAddress ??
                    item?.name ??
                    "Unknown Location"
                await MainActor.run {
                    self.placename = display
                }
            } catch {
                print("Reverse geocoding failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Conformance
extension LocationManager: LocationManaging {
    func snapshot() async -> LocationSnapshot? {
        let coord = location?.coordinate
        return LocationSnapshot(
            lat: coord?.latitude,
            lon: coord?.longitude,
            place: placename
        )
    }

    // You already have these in your manager; this just satisfies the protocol.
    // func requestPermissionAndLocation() { ... }
    // func refreshIfAuthorized() { ... }
}
