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
}
