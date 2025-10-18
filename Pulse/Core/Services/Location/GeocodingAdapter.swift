//
//  GeocodingAdapter.swift
//  Pulse
//
//  Created by Maury Alamin on 10/17/25.
//

import Foundation
import CoreLocation
import MapKit

struct GeocodingAdapter {
    /// Modern MapKit-based reverse geocode (iOS 26).
    /// Falls back to coordinate string if no readable address is found.
    static func reverseGeocode(using location: CLLocation) async -> String? {
        guard let request = MKReverseGeocodingRequest(location: location) else {
            return String(format: "%.4f, %.4f",
                          location.coordinate.latitude,
                          location.coordinate.longitude)
        }

        do {
            let items = try await request.mapItems
            if let item = items.first {
                // Prefer shortAddress or name; fallback to coordinate string.
                if let short = item.address?.shortAddress, !short.isEmpty {
                    return short
                } else if let name = item.name, !name.isEmpty {
                    return name
                } else {
                    let c = item.location.coordinate
                    return String(format: "%.4f, %.4f", c.latitude, c.longitude)
                }
            } else {
                let c = location.coordinate
                return String(format: "%.4f, %.4f", c.latitude, c.longitude)
            }
        } catch {
            print("Reverse-geocoding failed: \(error.localizedDescription)")
            let c = location.coordinate
            return String(format: "%.4f, %.4f", c.latitude, c.longitude)
        }
    }

    /// Legacy fallback (for pre-iOS 26 code paths if you need them).
    @available(iOS, deprecated: 26.0, message: "Use reverseGeocode(using:) instead.")
    static func reverseGeocodeLegacy(usingCLGeocoder location: CLLocation) async -> String? {
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            let pm = placemarks.first
            return pm?.name ?? pm?.locality ?? pm?.administrativeArea
        } catch {
            return nil
        }
    }
}
