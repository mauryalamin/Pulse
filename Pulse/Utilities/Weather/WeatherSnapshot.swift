//
//  WeatherSnapshot.swift
//  Pulse
//
//  Created by Maury Alamin on 5/21/25.
//

import Foundation
import CoreLocation

// MARK: - Protocol

protocol WeatherService {
    func fetchWeather(for coordinate: CLLocationCoordinate2D, at date: Date) async throws -> WeatherSnapshot
}

// MARK: - Model

struct WeatherSnapshot: Codable {
    var temperature: Double?
    var conditionCode: Int?
    
    var summary: String {
        WeatherSnapshot.codeDescription[conditionCode ?? -1] ?? "Unknown"
    }

    static let codeDescription: [Int: String] = [
        0: "Clear sky",
        1: "Mainly clear",
        2: "Partly cloudy",
        3: "Overcast",
        45: "Fog",
        48: "Rime fog",
        51: "Light drizzle",
        53: "Moderate drizzle",
        55: "Dense drizzle",
        61: "Light rain",
        63: "Moderate rain",
        65: "Heavy rain",
        71: "Light snow",
        73: "Moderate snow",
        75: "Heavy snow",
        80: "Light rain showers",
        81: "Moderate rain showers",
        82: "Violent rain showers"
    ]
    
    var sfSymbol: String {
        switch conditionCode {
        case 0: return "sun.max.fill"         // Clear
        case 1: return "sun.min.fill"         // Mainly clear
        case 2: return "cloud.sun.fill"       // Partly cloudy
        case 3: return "cloud.fill"           // Overcast
        case 45, 48: return "cloud.fog.fill"  // Fog
        case 51, 53, 55: return "cloud.drizzle.fill"
        case 61, 63, 65: return "cloud.rain.fill"
        case 71, 73, 75: return "snow"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        default: return "cloud"               // Fallback
        }
    }
}
