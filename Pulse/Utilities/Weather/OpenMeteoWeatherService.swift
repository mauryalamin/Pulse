//
//  OpenMeteoWeatherService.swift
//  Pulse
//
//  Created by Maury Alamin on 5/21/25.
//

import Foundation
import CoreLocation


class OpenMeteoWeatherService: WeatherService {
    func fetchWeather(for coordinate: CLLocationCoordinate2D, at date: Date) async throws -> WeatherSnapshot {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let urlString = """
        https://api.open-meteo.com/v1/forecast?latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&hourly=temperature_2m,weathercode&timezone=auto&start_date=\(dateString)&end_date=\(dateString)
        """

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let result = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

        guard let index = result.hourly.time.firstIndex(where: {
            $0.starts(with: dateString)
        }) else {
            return WeatherSnapshot(temperature: nil, conditionCode: nil)
        }

        let temperature = result.hourly.temperature_2m[safe: index]
        let code = result.hourly.weathercode[safe: index]

        return WeatherSnapshot(temperature: temperature, conditionCode: code)
    }
}

// MARK: - Open-Meteo API Model

private struct OpenMeteoResponse: Codable {
    struct Hourly: Codable {
        let time: [String]
        let temperature_2m: [Double]
        let weathercode: [Int]
    }

    let hourly: Hourly
}

// MARK: - Array Safe Access Helper

fileprivate extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
