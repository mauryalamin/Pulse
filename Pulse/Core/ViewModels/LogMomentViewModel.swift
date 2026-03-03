//
//  LogMomentViewModel.swift
//  Pulse
//
//  Created by Maury Alamin on 10/17/25.
//

import Foundation
import SwiftUI
import Observation
import SwiftData
import CoreLocation

@Observable
@MainActor
final class LogMomentViewModel {
    var selectedUrge: Urge? = nil
    var timestamp: Date = .now
    var intensity: Int? = nil
    var response: MomentResponse = .stayedPresent
    var notes: String = ""
    var selectedTags: [Tag] = []
    var weatherCode: Int = 0
    var temperatureCelsius: Double = 20
    var locationDescription: String = ""
    var latitude: Double?
    var longitude: Double?
    var errorMessage: String?
    private(set) var isSaving: Bool = false
    private(set) var hasCustomWeatherSnapshot = false
    private(set) var hasCustomLocationSnapshot = false
    
    @ObservationIgnored private let modelContext: ModelContext
    @ObservationIgnored private let createMoment: CreateMomentUseCase
    @ObservationIgnored private let location: LocationManaging
    
    init(modelContext: ModelContext,
         createMoment: CreateMomentUseCase,
         location: LocationManaging)
    {
        self.modelContext = modelContext
        self.createMoment = createMoment
        self.location = location
    }
    
    var canSave: Bool { selectedUrge != nil && intensity != nil && !isSaving}

    func setTimestamp(_ date: Date) {
        timestamp = date
    }

    func updateWeather(code: Int, temperatureCelsius: Double) {
        weatherCode = code
        self.temperatureCelsius = temperatureCelsius
        hasCustomWeatherSnapshot = true
    }

    func ingestAutoWeather(_ snapshot: WeatherSnapshot) {
        guard !hasCustomWeatherSnapshot else { return }
        if let code = snapshot.conditionCode {
            weatherCode = code
        }
        if let temperature = snapshot.temperature {
            temperatureCelsius = temperature
        }
    }

    func updateLocation(description: String?, latitude: Double?, longitude: Double?) {
        locationDescription = description ?? ""
        self.latitude = latitude
        self.longitude = longitude
        hasCustomLocationSnapshot = true
    }

    func ingestAutoLocation(_ snapshot: LocationSnapshot?) {
        guard !hasCustomLocationSnapshot, let snapshot else { return }
        locationDescription = snapshot.place ?? ""
        latitude = snapshot.lat
        longitude = snapshot.lon
    }
    
    @MainActor
    func save() async {
        print("🟢 VM.save — entered (canSave=\(canSave), isSaving=\(isSaving))")

        guard !isSaving else {
            print("🟡 VM.save — early exit: already saving")
            return
        }

        guard let urge = selectedUrge, let intensity = intensity else {
            print("🟡 VM.save — early exit: missing fields")
            errorMessage = "Missing required fields."
            return
        }

        isSaving = true
        defer {
            isSaving = false
            print("🔚 VM.save — exit")
        }

        let autoLocation = await location.snapshot()
        ingestAutoLocation(autoLocation)

        let resolvedLocation = LocationSnapshot(
            lat: latitude,
            lon: longitude,
            place: locationDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : locationDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        let weatherOverride: WeatherSnapshot? = hasCustomWeatherSnapshot
            ? WeatherSnapshot(temperature: temperatureCelsius, conditionCode: weatherCode)
            : nil

        let dto = CreateMomentDTO(
            urge: urge,
            intensity: intensity,
            response: response,
            notes: notes.isEmpty ? nil : notes,
            tags: selectedTags,
            location: resolvedLocation,
            weatherSnapshotOverride: weatherOverride,
            timestamp: timestamp
        )

        do {
            print("➡️ VM.save — calling use case…")
            try await createMoment(dto, in: modelContext)
            print("✅ VM.save — use case returned OK")
            errorMessage = nil
        } catch {
            print("❌ VM.save — use case threw: \(error)")
            errorMessage = error.localizedDescription
        }
    }
}

