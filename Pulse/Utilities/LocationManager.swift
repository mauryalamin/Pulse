//
//  LocationManager.swift
//  Pulse
//
//  Created by Maury Alamin on 5/20/25.
//

import Foundation
import CoreLocation
import SwiftUI

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @MainActor @Published var location: CLLocation?
    @MainActor @Published var placemark: CLPlacemark?
    @MainActor @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermissionAndLocation() {
        let status = manager.authorizationStatus

        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            // Don't call requestLocation() yet
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus

        Task { @MainActor in
            self.authorizationStatus = status
        }

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }

        Task { @MainActor in
            self.location = loc

            Task {
                do {
                    let placemarks = try await CLGeocoder().reverseGeocodeLocation(loc)
                    if let place = placemarks.first {
                        await MainActor.run {
                            self.placemark = place
                        }
                    }
                } catch {
                    print("Reverse geocoding failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
