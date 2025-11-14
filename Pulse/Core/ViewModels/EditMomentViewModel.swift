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
    var intensity: Int
    var response: MomentResponse
    var selectedTags: [Tag]
    var notes: String

    // You can reuse the same rule as LogMomentView if you like
    var canSave: Bool {
        selectedUrge != nil && intensity > 0
    }

    init(moment: Moment) {
        self.originalMoment = moment
        self.selectedUrge = moment.urge
        self.intensity = moment.intensity
        self.response = moment.gaveIn ? .followed : .stayedPresent
        self.selectedTags = moment.tags ?? []
        self.notes = moment.note ?? ""
    }
}
