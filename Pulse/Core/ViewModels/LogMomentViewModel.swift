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
    var intensity: Int? = nil
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
    
    var canSave: Bool { selectedUrge != nil && intensity != nil && !isSaving}
    
    @MainActor
    func save() async {
        // 1) Reentrancy gate — block double taps immediately
        guard !isSaving else { return }

        // 2) Validate required fields (don’t raise the gate if form is incomplete)
        guard let urge = selectedUrge, let intensity = intensity else {
            errorMessage = "Missing required fields."
            return
        }

        // 3) Raise the gate now (before any await)
        isSaving = true
        defer { isSaving = false }

        // 4) Build DTO (allow awaiting location AFTER the gate is up)
        let loc = await location.snapshot()   // ✅ use your existing API
        let dto = CreateMomentDTO(
            urge: urge,
            intensity: intensity,
            response: response,
            notes: notes.isEmpty ? nil : notes,
            tags: selectedTags,
            location: loc,
            timestamp: Date()
        )

        // 5) Persist via single insert path
        do {
            try await createMoment(dto, in: modelContext)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


