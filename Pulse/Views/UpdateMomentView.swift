//
//  UpdateMomentView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import SwiftUI

struct UpdateMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let moment: Moment
    
    @State private var selectedUrge: Urge?
    @State private var selectedIntensity: Int?
    @State private var noteText: String = ""
    @State private var selectedTags: [Tag] = []
    
    @State private var showDiscardAlert = false
    @State private var hasUnsavedChanges = false
    
    @State private var showTagPicker = false
    
    private func preloadFields() {
        selectedUrge = moment.urge
        selectedIntensity = moment.intensity
        noteText = moment.note ?? ""
        selectedTags = moment.tags ?? []
    }
    
    private func updateMoment() {
        guard let urge = selectedUrge, let intensity = selectedIntensity else { return }
        
        moment.urge = urge
        moment.intensity = intensity
        moment.note = noteText.isEmpty ? nil : noteText
        moment.tags = selectedTags
        
        try? modelContext.save()
        dismiss()
    }
    
    var body: some View {
        ZStack {
            Color(.grayBackground)
                .ignoresSafeArea()
            
            NavigationStack {
                Form {
                    Section(header: Text("Urge")) {
                        UrgeMenuView(selectedUrge: $selectedUrge)
                    }
                    
                    Section(header: Text("Intensity")) {
                        IntensityGroupView(selectedIntensity: $selectedIntensity)
                    }
                    
                    Section(header: Text("Note")) {
                        NoteInputView(text: $noteText)
                    }
                    
                    Section(header: Text("Tags")) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                            ForEach(selectedTags, id: \.id) { tag in
                                TagView(tag: tag.name)
                            }
                            
                            Button(action: {
                                showTagPicker = true
                            }) {
                                Label("Add", systemImage: "plus")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                    .background(Color.pulseBlue.opacity(0.2))
                                    .cornerRadius(6)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                }
                .navigationTitle("Edit Moment")
                // .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                if hasUnsavedChanges {
                                    showDiscardAlert = true
                                } else {
                                    dismiss()
                                }
                            }
                        }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { updateMoment() }
                            .disabled(selectedUrge == nil || selectedIntensity == nil)
                    }
                }
                
                .sheet(isPresented: $showTagPicker) {
                    TagPickerView(selectedTags: $selectedTags)
                }
                .alert("Discard changes?", isPresented: $showDiscardAlert) {
                            Button("Discard Changes", role: .destructive) {
                                dismiss()
                            }
                            Button("Keep Editing", role: .cancel) { }
                        } message: {
                            Text("You’ve made edits to this Moment. Are you sure you want to cancel?")
                        }
                .onAppear {
                    preloadFields()
                }
            }
            .onChange(of: selectedUrge) { _, _ in hasUnsavedChanges = true }
            .onChange(of: selectedIntensity) { _, _ in hasUnsavedChanges = true }
            .onChange(of: noteText) { _, _ in hasUnsavedChanges = true }
            .onChange(of: selectedTags) { _, _ in hasUnsavedChanges = true }
        }
    }
}

#Preview {
    NavigationStack {
        UpdateMomentView(moment: Moment(urge: Urge(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 5, gaveIn: false))
    }
}
