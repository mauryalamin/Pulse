//
//  EditMomentView.swift
//  Pulse
//
//  Created by Maury Alamin on 11/13/25.
//

import SwiftUI
import SwiftData

@MainActor
struct EditMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    let moment: Moment
    
    // Editing state
    @State private var vm: EditMomentViewModel
    @State private var showTagPicker = false
    @State private var notesFocused = false
    
    // MARK: - Init
    
    init(moment: Moment) {
        self.moment = moment
        _vm = State(initialValue: EditMomentViewModel(moment: moment))
    }
    
    // Bridge MomentResponse <-> Toggle Bool
    private var gaveInBinding: Binding<Bool> {
        Binding(
            get: { vm.response.gaveIn },
            set: { vm.response = $0 ? .followed : .stayedPresent }
        )
    }
    
    private var intensityBinding: Binding<Int?> {
        Binding<Int?>(
            get: { vm.intensity },
            set: { newValue in
                // If IntensityGroupView ever sends nil, keep the old value
                if let value = newValue {
                    vm.intensity = value
                }
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.grayBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // MARK: - Urge
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What did you feel the urge for?")
                                .font(.subheadline).fontWeight(.semibold)
                            UrgeMenuView(selectedUrge: $vm.selectedUrge)
                        }
                        
                        // MARK: - Intensity + Response
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("How strong was the urge?")
                                    .font(.subheadline).fontWeight(.semibold)
                                IntensityGroupView(
                                    selectedIntensity: intensityBinding,
                                    baseHex: vm.selectedUrge?.colorHex
                                )
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Urge\nFollowed?")
                                    .font(.subheadline).fontWeight(.semibold)
                                Toggle("Followed", isOn: gaveInBinding)
                                    .labelsHidden()
                            }
                        }
                        
                        // MARK: - Tags
                        VStack(alignment: .leading, spacing: 12) {
                            TagsFlowSection(
                                selectedTags: $vm.selectedTags,
                                showTagPicker: $showTagPicker
                            )
                        }
                        
                        // MARK: - Notes
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "text.bubble.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.green)
                                Text("Notes")
                                    .font(.subheadline).fontWeight(.semibold)
                            }
                            
                            NoteInputView(
                                text: $vm.notes,
                                isFocused: $notesFocused
                            )
                        }
                        
                        Divider().padding(.top, 4)
                        
                        // MARK: - Around This Moment (snapshot)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Around This Moment")
                                .font(.title3)
                                .fontWeight(.semibold)
                            // Editable Context Items
                            // Timestamp
                            // MARK: - Date and Time
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "clock")
                                    Text("When did this happen?")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }

                                DatePicker(
                                    "Date",
                                    selection: $vm.timestamp,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)

                                DatePicker(
                                    "Time",
                                    selection: $vm.timestamp,
                                    displayedComponents: [.hourAndMinute]
                                )
                                .datePickerStyle(.compact)
                            }
                            
                            
                            // Weather (only if we have a snapshot)
                            if let temperature = moment.temperature,
                               let _ = moment.weatherCode {
                                HStack(spacing: 6) {
                                    Image(systemName: moment.weatherIcon)
                                    Text(formattedTemperature(fromCelsius: temperature))
                                }
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            }
                            
                            // Location (only if we have one)
                            if let place = moment.locationDescription {
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(.secondary)
                                    Text(place)
                                }
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .sheet(isPresented: $showTagPicker) {
                TagPickerView(selectedTags: $vm.selectedTags)
            }
            .interactiveDismissDisabled(notesFocused)
            .navigationTitle("Edit Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .symbolRenderingMode(.monochrome)
                            .font(.headline)
                    }
                    .accessibilityLabel("Cancel")
                }

                // Save
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onSaveTapped()
                    } label: {
                        Image(systemName: "checkmark")
                            .symbolRenderingMode(.monochrome)
                            .font(.headline)
                            .frame(minWidth: 28, minHeight: 28)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.accentColor)
                    .disabled(!vm.canSave)
                    .opacity(vm.canSave ? 1 : 0.4)
                    .accessibilityLabel("Save Changes")
                }

                // Keyboard toolbar
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        notesFocused = false
                    }
                    .font(.body.weight(.semibold))
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formattedTemperature(fromCelsius celsius: Double) -> String {
        // Use the user’s measurement system (metric vs US/customary)
        let usesMetric = Locale.current.measurementSystem == .metric
        
        if usesMetric {
            // Celsius
            return String(format: "%.0f°C", celsius)
        } else {
            // Fahrenheit
            let f = celsius * 9.0 / 5.0 + 32.0
            return String(format: "%.0f°F", f)
        }
    }
    
    // MARK: - Save handler

    private func onSaveTapped() {
        do {
            try vm.save(in: context)
            dismiss()
        } catch {
            // For now, just log; later stories can surface an alert
            print("❌ EditMomentView save failed: \(error)")
        }
    }
}

#Preview {
    // let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
    // let tag1 = Tag(name: "After Work")
    // let tag2 = Tag(name: "Stress")
    
    let moment = Moment(
        timestamp: .now.addingTimeInterval(-3600), // 1 hour ago
        urge: Urge(name: "Alcohol", colorHex: "#8B3A3A"),
        intensity: 5,
        gaveIn: false,
        note: "Felt the urge after a long day, but stayed present.",
        tags: [
            Tag(name: "After Work"),
            Tag(name: "Stress Relief")
        ],
        locationDescription: "Chicago, IL",
        latitude: 41.8781,
        longitude: -87.6298,
        temperature: 13.6,
        weatherCode: 3 // cloud.fill in SF Symbols mapping
    )
    
    return NavigationStack {
        EditMomentView(moment: moment)
    }
}
