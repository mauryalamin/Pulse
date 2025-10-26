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

// MARK: - Use Case
struct CreateMomentUseCase {
    var weather: WeatherService
    init(weather: WeatherService) { self.weather = weather }

    func callAsFunction(_ dto: CreateMomentDTO, in ctx: ModelContext) async throws {
        print("🟩 UC.call — entered (ctx=\(ObjectIdentifier(ctx))) urge=\(dto.urge.name) intensity=\(dto.intensity) gaveIn=\(dto.response.gaveIn)")

        let newMoment = Moment(
            timestamp: dto.timestamp,
            urge: dto.urge,
            intensity: dto.intensity,
            gaveIn: dto.response.gaveIn,
            note: dto.notes,
            tags: dto.tags
        )

        if let loc = dto.location {
            newMoment.latitude = loc.lat
            newMoment.longitude = loc.lon
            // newMoment.locationDescription = loc.place
        }

        // Optional weather (ignored result)
        if let loc = dto.location {
            let coord = CLLocationCoordinate2D(latitude: loc.lat, longitude: loc.lon)
            _ = try? await weather.fetchWeather(for: coord, at: dto.timestamp)
        }

        try await persist(newMoment, in: ctx)
    }

    @MainActor
    private func persist(_ moment: Moment, in ctx: ModelContext) throws {
        print("🟡 persist: inserting… (ctx=\(ObjectIdentifier(ctx)))")
        ctx.insert(moment)
        try ctx.save()
        print("✅ Saved moment at \(moment.timestamp) — urge: \(moment.urge.name), intensity: \(moment.intensity)")

        NotificationCenter.default.post(name: .momentDidSave, object: nil)
    }
}
