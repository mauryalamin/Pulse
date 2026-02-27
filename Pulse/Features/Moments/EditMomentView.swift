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
    @State private var showLocationPlaceholderSheet = false
    
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
                                showLocationPlaceholderSheet = true
                            } label: {
                                EditableContextRow(
                                    iconName: "mappin.circle.fill",
                                    valueText: moment.locationDescription ?? "Add location"
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
            .sheet(isPresented: $showLocationPlaceholderSheet) {
                LocationPlaceholderSheet()
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

private struct EditableContextRow: View {
    let iconName: String
    let valueText: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .imageScale(.small)
                .foregroundStyle(.blue)

            Text(valueText)
                .font(.body)
                .foregroundStyle(.blue)
                .lineLimit(1)

            Spacer(minLength: 8)

            Image(systemName: "pencil")
                .imageScale(.small)
                .foregroundStyle(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct DateTimeEditSheet: View {
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

private struct WeatherEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draftWeatherCode: Int
    @State private var draftTemperatureCelsius: Double

    let weatherConditionOptions: [(code: Int, label: String)]
    let onSave: (Int, Double) -> Void

    init(
        initialWeatherCode: Int,
        initialTemperatureCelsius: Double,
        weatherConditionOptions: [(code: Int, label: String)],
        onSave: @escaping (Int, Double) -> Void
    ) {
        _draftWeatherCode = State(initialValue: initialWeatherCode)
        _draftTemperatureCelsius = State(initialValue: initialTemperatureCelsius)
        self.weatherConditionOptions = weatherConditionOptions
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Condition", selection: $draftWeatherCode) {
                    ForEach(weatherConditionOptions, id: \.code) { option in
                        Text(option.label).tag(option.code)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Image(systemName: WeatherFormatting.symbolName(for: nil, code: draftWeatherCode))
                        .foregroundStyle(.secondary)
                    Text(WeatherFormatting.formattedTempCompact(celsius: draftTemperatureCelsius))
                        .font(.body)
                }

                Stepper("Temperature", value: $draftTemperatureCelsius, in: -50...60, step: 1)
            }
            .navigationTitle("Edit Weather")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(draftWeatherCode, draftTemperatureCelsius)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct LocationPlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Location editing is coming soon.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
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
