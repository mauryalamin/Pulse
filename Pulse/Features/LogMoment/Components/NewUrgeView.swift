//
//  NewUrgeView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/15/25.
//

import SwiftUI

struct NewUrgeView: View {
    
    @Environment(\.dismiss) private var dismiss
        @Environment(\.modelContext) private var modelContext

        @State private var name: String = ""
        @State private var selectedColor: Color = .blue

        var onSave: (Urge) -> Void

    var body: some View {
        NavigationStack {
                    Form {
                        Section(header: Text("Urge Name")) {
                            TextField("e.g. Energy Drinks", text: $name)
                        }

                        Section(header: Text("Color")) {
                            ColorPicker("Pick a color", selection: $selectedColor, supportsOpacity: false)
                        }
                    }
                    .navigationTitle("New Urge")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { dismiss() }
                        }

                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                let urge = Urge(name: name, colorHex: selectedColor.toHex)
                                modelContext.insert(urge)
                                try? modelContext.save()
                                onSave(urge)
                                dismiss()
                            }
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
    }
}

#Preview {
    NewUrgeView(onSave: {_ in })
}
