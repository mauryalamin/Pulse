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
    let timestamp: Date               // match your model’s initializer

    init(urge: Urge,
         intensity: Int,
         response: MomentResponse,
         notes: String?,
         tags: [Tag],
         location: LocationSnapshot?,
         timestamp: Date = .now) {
        self.urge = urge
        self.intensity = intensity
        self.response = response
        self.notes = notes
        self.tags = tags
        self.location = location
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

        if let loc = dto.location {
            newMoment.latitude = loc.lat
            newMoment.longitude = loc.lon
            // newMoment.locationDescription = loc.place
        }

        // Optional: weather (doesn’t affect mapping)
        if let loc = dto.location, let lat = loc.lat, let lon = loc.lon {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            _ = try? await weather.fetchWeather(for: coord, at: dto.timestamp)
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
