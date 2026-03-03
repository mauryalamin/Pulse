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
    @State private var showDateTimeSheet = false
    @State private var showWeatherSheet = false
    @State private var showLocationSheet = false
    
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

    private let weatherConditionOptions: [(code: Int, label: String)] = WeatherSnapshot
        .codeDescription
        .sorted { $0.key < $1.key }
        .map { (code: $0.key, label: $0.value) }
    
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

                            Button {
                                showDateTimeSheet = true
                            } label: {
                                EditableContextRow(
                                    iconName: "calendar",
                                    valueText: vm.timestamp.formatted(date: .long, time: .shortened)
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                showWeatherSheet = true
                            } label: {
                                EditableContextRow(
                                    iconName: WeatherFormatting.symbolName(for: nil, code: vm.weatherCode),
                                    valueText: formattedTemperature(fromCelsius: vm.temperatureCelsius)
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                showLocationSheet = true
                            } label: {
                                EditableContextRow(
                                    iconName: "mappin.circle.fill",
                                    valueText: formattedLocationValue()
                                )
                            }
                            .buttonStyle(.plain)
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
            .sheet(isPresented: $showDateTimeSheet) {
                DateTimeEditSheet(
                    initialDate: vm.timestamp,
                    onSave: { newTimestamp in
                        vm.timestamp = newTimestamp
                    }
                )
            }
            .sheet(isPresented: $showWeatherSheet) {
                WeatherEditSheet(
                    initialWeatherCode: vm.weatherCode,
                    initialTemperatureCelsius: vm.temperatureCelsius,
                    weatherConditionOptions: weatherConditionOptions,
                    onSave: { code, temperature in
                        vm.hasWeatherSnapshot = true
                        vm.weatherCode = code
                        vm.temperatureCelsius = temperature
                    }
                )
            }
            .sheet(isPresented: $showLocationSheet) {
                LocationEditSheet(
                    initialLocationDescription: vm.locationDescription,
                    initialLatitude: vm.latitude,
                    initialLongitude: vm.longitude,
                    onSave: { locationDescription, latitude, longitude in
                        vm.locationDescription = locationDescription ?? ""
                        vm.latitude = latitude
                        vm.longitude = longitude
                    }
                )
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
        WeatherFormatting.formattedTempCompact(celsius: celsius)
    }

    private func formattedLocationValue() -> String {
        let trimmedDescription = vm.locationDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDescription.isEmpty {
            return trimmedDescription
        }

        if vm.latitude != nil, vm.longitude != nil {
            return "Saved location"
        }

        return "Add location"
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
