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
    @State private var gaveIn = false
    @State private var locationDescription: String?
    @State private var showDeleteLocationAlert = false
    
    @State private var showDiscardAlert = false
    
    @State private var showTagPicker = false
    
    @StateObject private var keyboard = KeyboardResponder()
    @StateObject private var locationManager = LocationManager()
    
    private func preloadFields() {
        selectedUrge = moment.urge
        selectedIntensity = moment.intensity
        noteText = moment.note ?? ""
        selectedTags = moment.tags ?? []
        gaveIn = moment.gaveIn
        locationDescription = moment.locationDescription
    }
    
    private func updateMoment() {
        guard let urge = selectedUrge, let intensity = selectedIntensity else { return }

        moment.urge = urge
        moment.intensity = intensity
        moment.note = noteText.isEmpty ? nil : noteText
        moment.tags = selectedTags
        moment.gaveIn = gaveIn
        moment.locationDescription = locationDescription

        try? modelContext.save()
        dismiss()
    }
    
    private func hasChangesCompared(to moment: Moment) -> Bool {
        if selectedUrge?.id != moment.urge.id { return true }
        if selectedIntensity != moment.intensity { return true }
        if noteText != (moment.note ?? "") { return true }
        if gaveIn != moment.gaveIn { return true }
        if locationDescription != moment.locationDescription { return true }

        let selectedTagIDs = Set(selectedTags.map(\.id))
        let originalTagIDs = Set((moment.tags ?? []).map(\.id))
        if selectedTagIDs != originalTagIDs { return true }

        return false
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.grayBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    // MARK: - View Content
                    
                    VStack (alignment: .leading, spacing: 32) {
                        // MARK: - Urge Picker
                        VStack (alignment: .leading, spacing: 12){
                            Text("What do you feel the urge for?")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            UrgeMenuView(selectedUrge: $selectedUrge)
                        }
                        
                        // MARK: - Intensity
                        HStack (spacing: 24) {
                            VStack (alignment: .leading, spacing: 12){
                                Text("How strong is the urge?")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                IntensityGroupView(selectedIntensity: $selectedIntensity)
                            }
                            Divider()
                            VStack (alignment: .leading, spacing: 12) {
                                Text("Urge\rFollowed?")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Toggle("Filter", isOn: $gaveIn)
                                    .labelsHidden()
                            }
                        }
                        
                        // MARK: - Tags
                        VStack (alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 6)] ,alignment: .leading, spacing: 6) {
                                ForEach(selectedTags, id: \.id) { tag in
                                    TagView(tag: tag.name)
                                }
                                
                                Button(action: {
                                    showTagPicker = true
                                }) {
                                    Label("Add", systemImage: "plus")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 4)
                                        .foregroundColor(.blue)
                                        .background(Color.pulseBlue.opacity(0.2))
                                        .cornerRadius(6)
                                        .font(.subheadline)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // MARK: - Notes
                        VStack (alignment: .leading, spacing: 12) {
                            Text("Optional Notes")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            NoteInputView(text: $noteText)
                        }
                        
                        Divider()
                        
                        // MARK: - Location
                        VStack (alignment: .leading, spacing: 12) {
                            Text("Location")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            let nonOptionalLocation = Binding<String>(
                                get: { locationDescription ?? "" },
                                set: { locationDescription = $0 }
                            )
                            if locationDescription != nil {
                                TextField("Location", text: nonOptionalLocation)
                                    .textInputAutocapitalization(.words)

                                Button("Remove Location", role: .destructive) {
                                    showDeleteLocationAlert = true
                                }
                                .alert("Remove Location?", isPresented: $showDeleteLocationAlert) {
                                    Button("Remove", role: .destructive) {
                                        locationDescription = nil
                                    }
                                    Button("Cancel", role: .cancel) { }
                                } message: {
                                    Text("This Moment’s location will be permanently removed.")
                                }
                                Button("Update with My Current Location") {
                                    locationManager.requestPermissionAndLocation()
                                }
                            } else {
                                Text("No location was captured.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        // MARK: - Button Group
                        HStack {
                            Spacer()
                            VStack (spacing: 24) {
                                Button("Save") { updateMoment() }
                                    .disabled(selectedUrge == nil || selectedIntensity == nil)
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.large)
                                
                                Button("Cancel") {
                                    if hasChangesCompared(to: moment) {
                                                showDiscardAlert = true
                                            } else {
                                                dismiss()
                                            }
                                }
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .navigationTitle("Edit Moment")
                    
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                if hasChangesCompared(to: moment) {
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
                    .task {
                        preloadFields()
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .animation(.easeInOut(duration: 0.3), value: keyboard.keyboardHeight)
            }
        }
        
    }
}

#Preview {
    NavigationStack {
        UpdateMomentView(moment: Moment(timestamp: .now, urge: Urge(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 5, gaveIn: false))
    }
}
