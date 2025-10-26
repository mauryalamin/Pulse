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
    private(set) var isSaving: Bool = false
    
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

        let loc = await location.snapshot()
        let dto = CreateMomentDTO(
            urge: urge,
            intensity: intensity,
            response: response,
            notes: notes.isEmpty ? nil : notes,
            tags: selectedTags,
            location: loc,
            timestamp: Date()
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


