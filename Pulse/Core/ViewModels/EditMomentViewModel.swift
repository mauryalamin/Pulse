//
//  EditMomentViewModel.swift
//  Pulse
//
//  Created by Maury Alamin on 11/14/25.
//

import Foundation
import SwiftData
import Observation

@Observable
final class EditMomentViewModel {

    // The original record we’re editing
    let originalMoment: Moment

    // Editable fields
    var selectedUrge: Urge?
    var timestamp: Date
    var intensity: Int
    var response: MomentResponse
    var selectedTags: [Tag]
    var notes: String
    var hasWeatherSnapshot: Bool
    var weatherCode: Int
    var temperatureCelsius: Double
    var locationDescription: String
    var latitude: Double?
    var longitude: Double?

    // You can reuse the same rule as LogMomentView if you like
    var canSave: Bool {
        selectedUrge != nil && intensity > 0
    }

    init(moment: Moment) {
        self.originalMoment = moment
        self.selectedUrge = moment.urge
        self.timestamp = moment.timestamp
        self.intensity = moment.intensity
        self.response = moment.gaveIn ? .followed : .stayedPresent
        self.selectedTags = moment.tags ?? []
        self.notes = moment.note ?? ""
        self.hasWeatherSnapshot = moment.temperature != nil || moment.weatherCode != nil
        self.weatherCode = moment.weatherCode ?? 0
        self.temperatureCelsius = moment.temperature ?? 20
        self.locationDescription = moment.locationDescription ?? ""
        self.latitude = moment.latitude
        self.longitude = moment.longitude
    }

    /// Apply the edited values back onto the SwiftData `Moment` and save.
    @MainActor
    func save(in context: ModelContext) throws {
        // Don’t try to save if the form is invalid
        guard canSave else { return }

        // 1) Urge — keep in sync with editor
        if let newUrge = selectedUrge {
            originalMoment.urge = newUrge
        }

        // 2) Intensity
        originalMoment.intensity = intensity

        // 3) Timestamp
        originalMoment.timestamp = timestamp

        // 4) Response → maps onto gaveIn Bool
        originalMoment.gaveIn = response.gaveIn

        // 5) Notes (normalize empty → nil)
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        originalMoment.note = trimmed.isEmpty ? nil : trimmed

        // 6) Tags
        originalMoment.tags = selectedTags

        // 7) Weather snapshot
        if hasWeatherSnapshot {
            originalMoment.weatherCode = weatherCode
            originalMoment.temperature = temperatureCelsius
        } else {
            originalMoment.weatherCode = nil
            originalMoment.temperature = nil
        }

        // 8) Location snapshot (keep label optional, coordinates internal)
        let trimmedLocation = locationDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        originalMoment.locationDescription = trimmedLocation.isEmpty ? nil : trimmedLocation

        if let latitude, let longitude {
            originalMoment.latitude = latitude
            originalMoment.longitude = longitude
        } else {
            originalMoment.latitude = nil
            originalMoment.longitude = nil
        }

        // 9) Persist to SwiftData
        try context.save()
    }
}
