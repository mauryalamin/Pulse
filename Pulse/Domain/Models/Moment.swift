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
    
    var temperature: Double?
    var weatherCode: Int?
    
    init(timestamp: Date, urge: Urge, intensity: Int, gaveIn: Bool, note: String? = nil, tags: [Tag]? = nil, locationDescription: String? = nil, latitude: Double? = nil, longitude: Double? = nil, temperature: Double? = nil, weatherCode: Int? = nil) {
        self.timestamp = timestamp
        self.urge = urge
        self.intensity = intensity
        self.gaveIn = gaveIn
        self.note = note
        self.tags = tags
        self.locationDescription = locationDescription
        self.latitude = latitude
        self.longitude = longitude
        self.temperature = temperature
        self.weatherCode = weatherCode
    }
}

extension Moment {
    
    var weatherIcon: String {
        WeatherSnapshot(temperature: temperature, conditionCode: weatherCode).sfSymbol
    }
    
    /// Formats the saved temperature to the user’s unit (°F/°C).
    var formattedTemperature: String? {
        guard let t = temperature else { return nil }
        let measurement = Measurement(value: t, unit: UnitTemperature.celsius) // store is Celsius
        let usesF = Locale.current.usesFahrenheit
        let display = usesF ? measurement.converted(to: .fahrenheit) : measurement
        let fmt = MeasurementFormatter()
        fmt.unitOptions = .providedUnit
        fmt.unitStyle = .short
        return fmt.string(from: display) // e.g., "65°F" or "18°C"
    }

    /// Single string for UI like: "☁️ 65°F"
    var weatherBadge: String? {
        guard let temp = formattedTemperature, weatherCode != nil else { return nil }
        return "\(weatherIcon) \(temp)"
    }
}

private extension Locale {
    var usesFahrenheit: Bool {
        ((self as NSLocale).object(forKey: .measurementSystem) as? String)?
            .lowercased() == "us"
    }
}
