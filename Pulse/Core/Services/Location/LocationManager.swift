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

/// iOS 26-ready LocationManager:
/// - No @MainActor on the class (avoids Swift 6 protocol-isolation warning)
/// - Uses MKReverseGeocodingRequest(location:) + await request.mapItems
/// - Mutates observable state on the main actor
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate, LocationManaging {

    static let shared = LocationManager()

    // Observable state (updated on MainActor)
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var location: CLLocation?
    var placename: String?

    private let manager = CLLocationManager()

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: - Public API (UI can call these)
    @MainActor
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

    /// One-shot snapshot used by your VMs.
    @MainActor
    func snapshot() async -> LocationSnapshot? {
        if let loc = location {
            return LocationSnapshot(lat: loc.coordinate.latitude,
                                    lon: loc.coordinate.longitude,
                                    place: placename)
        }
        requestPermissionAndLocation()
        // Give the delegate a moment to deliver an update.
        try? await Task.sleep(for: .seconds(1.5))
        guard let loc = location else { return nil }
        return LocationSnapshot(lat: loc.coordinate.latitude,
                                lon: loc.coordinate.longitude,
                                place: placename)
    }

    // MARK: - CLLocationManagerDelegate (nonisolated, hop to main for state)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                self.manager.requestLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        Task { @MainActor in
            self.location = loc
        }

        Task {
            // Reverse-geocode with the new MapKit API (iOS 26)
            if let request = MKReverseGeocodingRequest(location: loc) {
                do {
                    let items = try await request.mapItems
                    if let item = items.first {
                        // Prefer the new shortAddress, then name, then coords as a last resort
                        let display: String = {
                            if let short = item.address?.shortAddress, !short.isEmpty {
                                return short
                            } else if let name = item.name, !name.isEmpty {
                                return name
                            } else {
                                let c = item.location.coordinate
                                return String(format: "%.4f, %.4f", c.latitude, c.longitude)
                            }
                        }()

                        await MainActor.run { self.placename = display }
                    } else {
                        await MainActor.run { self.placename = nil }
                    }
                } catch {
                    await MainActor.run { self.placename = nil }
                    print("Reverse-geocoding failed: \(error.localizedDescription)")
                }
            } else {
                await MainActor.run { self.placename = nil }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
