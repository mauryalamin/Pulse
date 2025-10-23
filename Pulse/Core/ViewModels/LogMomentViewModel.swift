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
    
    @MainActor
    func save() async {
        print("🟡 VM.save: begin")
        do {
            guard let urge = selectedUrge, let intensity = intensity else {
                print("🔺 VM.save: missing fields");
                self.errorMessage = "Missing fields"
                return
            }

            let dto = CreateMomentDTO(
                urge: urge,
                intensity: intensity,
                response: response,
                notes: notes.isEmpty ? nil : notes,
                tags: selectedTags,
                location: await location.snapshot(),
                timestamp: .now
            )

            print("🟡 VM.save: calling useCase")
            try await createMoment(dto, in: modelContext)
            print("🟢 VM.save: useCase returned OK")

            self.errorMessage = nil
        } catch {
            print("🔴 VM.save: error \(error)")
            self.errorMessage = error.localizedDescription
        }
    }
}


