//
//  CreateMomentUseCase.swift
//  Pulse
//
//  Created by Maury Alamin on 10/17/25.
//

import Foundation
import SwiftData
import CoreLocation

extension Notification.Name {
    static let momentDidSave = Notification.Name("momentDidSave")
}

// MARK: - DTO
struct CreateMomentDTO {
    let urge: Urge
    let intensity: Int
    let response: MomentResponse      // maps to `gaveIn`
    let notes: String?
    let tags: [Tag]
    let location: LocationSnapshot?
    let weatherSnapshotOverride: WeatherSnapshot?
    let timestamp: Date               // match your model’s initializer

    init(urge: Urge,
         intensity: Int,
         response: MomentResponse,
         notes: String?,
         tags: [Tag],
         location: LocationSnapshot?,
         weatherSnapshotOverride: WeatherSnapshot? = nil,
         timestamp: Date = .now) {
        self.urge = urge
        self.intensity = intensity
        self.response = response
        self.notes = notes
        self.tags = tags
        self.location = location
        self.weatherSnapshotOverride = weatherSnapshotOverride
        self.timestamp = timestamp
    }
}

// Serializes saves per ModelContext (not globally)
actor SaveGate {
    static let shared = SaveGate()
    private var inFlight: Set<ObjectIdentifier> = []

    func begin(_ ctx: ModelContext) -> Bool {
        let id = ObjectIdentifier(ctx)
        if inFlight.contains(id) { return false }
        inFlight.insert(id)
        return true
    }

    func end(_ ctx: ModelContext) {
        inFlight.remove(ObjectIdentifier(ctx))
    }
}

// MARK: - Use Case
struct CreateMomentUseCase {
    var weather: WeatherService
    init(weather: WeatherService) { self.weather = weather }

    @MainActor
    func callAsFunction(_ dto: CreateMomentDTO, in ctx: ModelContext) async throws {
        // 🛡️ Reentrancy guard PER CONTEXT (won’t block other tests/contexts)
        guard await SaveGate.shared.begin(ctx) else {
            print("⚠️ CreateMomentUseCase: duplicate save attempt skipped (same context)")
            return
        }
        defer { Task { await SaveGate.shared.end(ctx) } }

        print("🟡 CreateMomentUseCase: start (ctx=\(ObjectIdentifier(ctx)))")

        // Normalize notes: trim → nil if empty
        let normalizedNotes: String? = {
            guard let raw = dto.notes?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
            return raw.isEmpty ? nil : raw
        }()

        // Build model
        let newMoment = Moment(
            timestamp: dto.timestamp,
            urge: dto.urge,
            intensity: dto.intensity,
            gaveIn: dto.response.gaveIn,
            note: normalizedNotes,
            tags: dto.tags
        )

        // Map location snapshot directly to stored properties
        if let loc = dto.location {
            newMoment.locationDescription = loc.place
            newMoment.latitude = loc.lat
            newMoment.longitude = loc.lon
        }

        if let override = dto.weatherSnapshotOverride {
            newMoment.temperature = override.temperature
            newMoment.weatherCode = override.conditionCode
        } else if let loc = dto.location,
                  let lat = loc.lat, let lon = loc.lon {
            // Optional: resolve weather *once* and store the snapshot
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            if let snap = try? await weather.fetchWeather(for: coord, at: dto.timestamp) {
                // Store as model fields for later display in Detail
                newMoment.temperature = snap.temperature        // Celsius
                newMoment.weatherCode = snap.conditionCode
            }
        }

        try persist(newMoment, in: ctx)
    }

    @MainActor
    private func persist(_ moment: Moment, in ctx: ModelContext) throws {
        print("🟡 persist: inserting… (ctx=\(ObjectIdentifier(ctx)))")
        if moment.modelContext == nil {
            ctx.insert(moment)
        }
        try ctx.save()
        print("✅ save() committed — moment id:", moment.persistentModelID)

        NotificationCenter.default.post(name: .momentDidSave, object: nil)
    }
}
