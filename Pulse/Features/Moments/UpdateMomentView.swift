//
//  UpdateMomentView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import SwiftUI
import SwiftData
import CoreLocation

struct UpdateMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let moment: Moment

    // Form state
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

    // ⬇️ Use the singleton LocationManager with Observation, not @StateObject
    @State private var locationManager = LocationManager.shared

    private func preloadFields() {
        selectedUrge = moment.urge
        selectedIntensity = moment.intensity
        noteText = moment.note ?? ""
        selectedTags = moment.tags ?? []
        gaveIn = moment.gaveIn
        locationDescription = moment.locationDescription
    }

    private func applyEdits() {
        guard let urge = selectedUrge, let intensity = selectedIntensity else { return }
        moment.urge = urge
        moment.intensity = intensity
        moment.gaveIn = gaveIn
        moment.note = noteText.isEmpty ? nil : noteText
        moment.tags = selectedTags

        // If you allow editing location text, keep it in sync
        moment.locationDescription = locationDescription

        try? modelContext.save()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.grayBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Urge
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Urge Type").font(.subheadline).fontWeight(.semibold)
                            UrgeMenuView(selectedUrge: $selectedUrge)
                        }

                        // Intensity + Followed
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Intensity").font(.subheadline).fontWeight(.semibold)
                                IntensityGroupView(selectedIntensity: $selectedIntensity)
                            }
                            Divider()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Urge\nFollowed?").font(.subheadline).fontWeight(.semibold)
                                Toggle("Followed", isOn: $gaveIn).labelsHidden()
                            }
                        }

                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags").font(.subheadline).fontWeight(.semibold)
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 90), spacing: 6)],
                                alignment: .leading,
                                spacing: 6
                            ) {
                                ForEach(selectedTags, id: \.id) { tag in
                                    TagView(tag: tag.name)
                                }
                                Button {
                                    showTagPicker = true
                                } label: {
                                    Label("Add", systemImage: "plus")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 4)
                                        .background(Color.pulseBlue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .font(.subheadline)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes").font(.subheadline).fontWeight(.semibold)
                            // **** NoteInputView(text: $noteText)
                        }

                        Divider()

                        // Location snippet / actions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location").font(.subheadline).fontWeight(.semibold)

                            if let desc = locationDescription, !desc.isEmpty {
                                HStack {
                                    Text("📍 \(desc)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                    Spacer()
                                    Button(role: .destructive) {
                                        showDeleteLocationAlert = true
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                    .labelStyle(.iconOnly)
                                }
                            } else if locationManager.authorizationStatus == .authorizedWhenInUse ||
                                        locationManager.authorizationStatus == .authorizedAlways {
                                Text("📍 No saved location. You can re-capture current location from the Log screen.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("📍 Location permission not granted.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    Spacer().frame(height: keyboard.keyboardHeight + 24)
                }
                .scrollDismissesKeyboard(.interactively)
                .animation(.easeInOut(duration: 0.25), value: keyboard.keyboardHeight)
            }
            .navigationTitle("Edit Moment")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if selectedUrge == nil || selectedIntensity == nil {
                            // Optional: show an alert to require both fields
                        } else {
                            applyEdits()
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showTagPicker) {
                TagPickerView(selectedTags: $selectedTags)
            }
            .alert("Remove saved location?", isPresented: $showDeleteLocationAlert) {
                Button("Delete", role: .destructive) {
                    locationDescription = nil
                    moment.locationDescription = nil
                    moment.latitude = nil
                    moment.longitude = nil
                    try? modelContext.save()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove the saved location from this moment.")
            }
            .alert("Discard changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes.")
            }
            .task {
                // Preload fields when the view appears
                preloadFields()
            }
        }
    }

    private var hasUnsavedChanges: Bool {
        (selectedUrge?.id != moment.urge.id) ||
        (selectedIntensity != moment.intensity) ||
        (noteText != (moment.note ?? "")) ||
        (selectedTags != (moment.tags ?? [])) ||
        (gaveIn != moment.gaveIn) ||
        (locationDescription != moment.locationDescription)
    }
}
