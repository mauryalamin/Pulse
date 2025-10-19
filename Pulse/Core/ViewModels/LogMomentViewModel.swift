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
    var selectedUrge: Urge?
    var intensity: Int?          // <- optional so nothing is preselected
    var response: MomentResponse = .stayedPresent
    var notes: String = ""
    var selectedTags: [Tag] = []
    var errorMessage: String?
    var isSaving = false

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

    var canSave: Bool { selectedUrge != nil && intensity != nil }

    func save() async {
            guard !isSaving else { return }
            isSaving = true
            defer { isSaving = false }

            guard let urge = selectedUrge, let intensity = intensity else {
                errorMessage = "A Moment needs both an Urge and an Intensity."
                return
            }

            let dto = CreateMomentDTO(
                urge: urge, intensity: intensity, response: response,
                notes: notes.isEmpty ? nil : notes, tags: selectedTags,
                location: await location.snapshot(), timestamp: .now
            )

            do { try await createMoment(dto, in: modelContext) }
            catch { errorMessage = "Could not save moment: \(error.localizedDescription)" }
        }
}
