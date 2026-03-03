//
//  DateTimeEditSheet.swift
//  Pulse
//
//  Created by Codex on 3/3/26.
//

import SwiftUI

struct DateTimeEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draftDate: Date
    let onSave: (Date) -> Void

    init(initialDate: Date, onSave: @escaping (Date) -> Void) {
        _draftDate = State(initialValue: initialDate)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $draftDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical)

                DatePicker("Time", selection: $draftDate, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.wheel)
            }
            .navigationTitle("Edit Date & Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(draftDate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
#Preview {
    DateTimeEditSheet(initialDate: .now) { _ in }
}

