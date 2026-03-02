//
//  EditMomentView.swift
//  Pulse
//
//  Created by Maury Alamin on 11/13/25.
//

import SwiftUI
import SwiftData
import MapKit
import UIKit

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

private struct LocationEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var locationManager = LocationManager.shared
    @State private var draftLocationQuery: String
    @State private var suggestions: [LocationSuggestion] = []
    @State private var selectedSuggestionID: String?
    @State private var isLoading = false
    @State private var resolutionError: String?
    @State private var completer = MKLocalSearchCompleter()
    @State private var completerDelegate = LocationSearchCompleterDelegate()
    @State private var pendingQueryTask: Task<Void, Never>?
    @State private var shouldSelectAllOnFocus = false
    @FocusState private var isSearchFieldFocused: Bool

    let onSave: (_ locationDescription: String?, _ latitude: Double?, _ longitude: Double?) -> Void
    private let originalLocationDescription: String
    private let originalLatitude: Double?
    private let originalLongitude: Double?

    init(
        initialLocationDescription: String,
        initialLatitude: Double?,
        initialLongitude: Double?,
        onSave: @escaping (_ locationDescription: String?, _ latitude: Double?, _ longitude: Double?) -> Void
    ) {
        let initialQuery = initialLocationDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        _draftLocationQuery = State(initialValue: initialQuery)
        self.originalLocationDescription = initialLocationDescription
        self.originalLatitude = initialLatitude
        self.originalLongitude = initialLongitude
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if let originalSuggestion {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(originalSuggestion.title)
                                    .font(.headline)
                                Text("Moment Location")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }
                }

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search Locations", text: $draftLocationQuery)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .submitLabel(.search)
                        .focused($isSearchFieldFocused)
                        .onTapGesture {
                            shouldSelectAllOnFocus = true
                            isSearchFieldFocused = true
                        }
                        .onSubmit {
                            Task { await saveSelection() }
                        }
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)

                if let resolutionError {
                    Text(resolutionError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                }

                List {
                    ForEach(suggestions) { suggestion in
                        Button {
                            selectedSuggestionID = suggestion.id
                            draftLocationQuery = suggestion.title
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: suggestion.isCurrentLocation ? "location.fill" : "mappin.circle.fill")
                                    .foregroundStyle(suggestion.isCurrentLocation ? .gray : .red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    if !suggestion.subtitle.isEmpty {
                                        Text(suggestion.subtitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                if selectedSuggestionID == suggestion.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)

                Button("Clear Location", role: .destructive) {
                    onSave(nil, nil, nil)
                    dismiss()
                }
                .padding(.bottom, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.semibold))
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5), in: Circle())
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await saveSelection() }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(.blue, in: Circle())
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                locationManager.requestPermissionAndLocation()
                configureCompleter()
                await updateSuggestions(for: draftLocationQuery)
            }
            .onChange(of: draftLocationQuery) { _, newQuery in
                selectedSuggestionID = nil
                queueSuggestionRefresh(for: newQuery)
            }
            .onChange(of: isSearchFieldFocused) { _, isFocused in
                guard isFocused, shouldSelectAllOnFocus else { return }
                shouldSelectAllOnFocus = false
                DispatchQueue.main.async {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.selectAll(_:)),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            }
            .onDisappear {
                pendingQueryTask?.cancel()
            }
        }
    }

    private var originalSuggestion: LocationSuggestion? {
        let trimmed = originalLocationDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return LocationSuggestion(
                id: "original-\(trimmed)",
                title: trimmed,
                subtitle: "",
                latitude: originalLatitude,
                longitude: originalLongitude,
                isCurrentLocation: false
            )
        }
        return nil
    }

    private var selectedSuggestion: LocationSuggestion? {
        suggestions.first(where: { $0.id == selectedSuggestionID })
    }

    private func queueSuggestionRefresh(for query: String) {
        pendingQueryTask?.cancel()
        pendingQueryTask = Task {
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            await updateSuggestions(for: query)
        }
    }

    private func configureCompleter() {
        completer.resultTypes = [.address, .pointOfInterest]
        if let userLocation = locationManager.location {
            completer.region = MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 8_000,
                longitudinalMeters: 8_000
            )
        }
        completerDelegate.onResults = { completions in
            Task { @MainActor in
                await ingestCompletions(completions)
            }
        }
        completerDelegate.onError = { error in
            Task { @MainActor in
                resolutionError = error.localizedDescription
                isLoading = false
            }
        }
        completer.delegate = completerDelegate
    }

    private func updateSuggestions(for query: String) async {
        isLoading = true
        resolutionError = nil
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            await loadDefaultNearbySuggestions()
            isLoading = false
            return
        }
        completer.queryFragment = trimmed
    }

    private func ingestCompletions(_ completions: [MKLocalSearchCompletion]) async {
        let topCompletions = Array(completions.prefix(12))
        let userLocation = locationManager.location
        var resolved: [LocationSuggestion] = []

        for completion in topCompletions {
            let request = MKLocalSearch.Request(completion: completion)
            if let userLocation {
                request.region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    latitudinalMeters: 10_000,
                    longitudinalMeters: 10_000
                )
            }
            let response = try? await MKLocalSearch(request: request).start()
            if let mapItem = response?.mapItems.first {
                resolved.append(
                    suggestion(from: mapItem, userLocation: userLocation, fallbackTitle: completion.title)
                )
            }
        }

        suggestions = deduplicateAndSort(resolved)
        isLoading = false
    }

    private func loadDefaultNearbySuggestions() async {
        let userLocation = locationManager.location
        guard let userLocation else {
            suggestions = []
            return
        }

        var current = [LocationSuggestion]()
        let placename = locationManager.placename?.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentTitle = (placename?.isEmpty == false) ? placename! : "Current Location"
        current.append(
            LocationSuggestion(
                id: "current-location",
                title: currentTitle,
                subtitle: subtitle(distanceInMeters: 0, town: townName(from: nil), isCurrentLocation: true),
                latitude: userLocation.coordinate.latitude,
                longitude: userLocation.coordinate.longitude,
                isCurrentLocation: true
            )
        )

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "landmark"
        request.region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: 8_000,
            longitudinalMeters: 8_000
        )
        let response = try? await MKLocalSearch(request: request).start()
        let nearby = response?.mapItems.prefix(16).map {
            suggestion(from: $0, userLocation: userLocation, fallbackTitle: $0.name ?? "Nearby Place")
        } ?? []

        suggestions = deduplicateAndSort(current + nearby)
    }

    private func saveSelection() async {
        resolutionError = nil
        if let selectedSuggestion {
            onSave(selectedSuggestion.title, selectedSuggestion.latitude, selectedSuggestion.longitude)
            dismiss()
            return
        }

        let query = draftLocationQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            onSave(nil, nil, nil)
            dismiss()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            guard let request = MKGeocodingRequest(addressString: query) else {
                resolutionError = "Enter a location name, address, or ZIP code."
                return
            }
            let mapItems = try await request.mapItems
            guard let mapItem = mapItems.first else {
                resolutionError = "Couldn’t find that location. Try a full address or ZIP code."
                return
            }

            let coordinate = mapItem.location.coordinate
            let resolvedName = displayName(from: mapItem, fallback: query)
            onSave(resolvedName, coordinate.latitude, coordinate.longitude)
            dismiss()
        } catch {
            resolutionError = "Couldn’t resolve location right now. Check connection and try again."
        }
    }

    private func deduplicateAndSort(_ input: [LocationSuggestion]) -> [LocationSuggestion] {
        var seen: Set<String> = []
        let unique = input.filter { seen.insert($0.id).inserted }
        return unique.sorted { lhs, rhs in
            if lhs.isCurrentLocation != rhs.isCurrentLocation {
                return lhs.isCurrentLocation
            }
            return lhs.distanceInMeters ?? .greatestFiniteMagnitude < rhs.distanceInMeters ?? .greatestFiniteMagnitude
        }
    }

    private func suggestion(from mapItem: MKMapItem, userLocation: CLLocation?, fallbackTitle: String) -> LocationSuggestion {
        let coordinate = mapItem.location.coordinate
        let title = displayName(from: mapItem, fallback: fallbackTitle)
        let distance = userLocation.map { $0.distance(from: mapItem.location) }
        let town = townName(from: mapItem)
        return LocationSuggestion(
            id: "\(title.lowercased())-\(coordinate.latitude)-\(coordinate.longitude)",
            title: title,
            subtitle: subtitle(distanceInMeters: distance, town: town, isCurrentLocation: false),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            isCurrentLocation: false,
            distanceInMeters: distance
        )
    }

    private func displayName(from mapItem: MKMapItem, fallback: String) -> String {
        if let shortAddress = mapItem.address?.shortAddress, !shortAddress.isEmpty {
            return shortAddress
        }

        if let name = mapItem.name, !name.isEmpty {
            return name
        }

        return fallback
    }

    private func townName(from mapItem: MKMapItem?) -> String {
        guard let mapItem else { return locationManager.placename ?? "" }
        return mapItem.addressRepresentations?.cityName
            ?? mapItem.addressRepresentations?.cityWithContext
            ?? mapItem.address?.shortAddress
            ?? ""
    }

    private func subtitle(distanceInMeters: CLLocationDistance?, town: String, isCurrentLocation: Bool) -> String {
        let townText = town.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix: String
        if isCurrentLocation {
            prefix = "Current Location"
        } else {
            prefix = distanceLabel(from: distanceInMeters)
        }

        if townText.isEmpty { return prefix }
        return "\(prefix) • \(townText)"
    }

    private func distanceLabel(from meters: CLLocationDistance?) -> String {
        guard let meters else { return "Nearby" }
        if meters < 1609 {
            let feet = Int((meters * 3.28084).rounded())
            return "\(max(feet, 1)) ft"
        }

        let miles = meters / 1609.34
        return String(format: "%.1f mi", miles)
    }
}

private struct LocationSuggestion: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let latitude: Double?
    let longitude: Double?
    let isCurrentLocation: Bool
    let distanceInMeters: CLLocationDistance?

    init(
        id: String,
        title: String,
        subtitle: String,
        latitude: Double?,
        longitude: Double?,
        isCurrentLocation: Bool,
        distanceInMeters: CLLocationDistance? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.latitude = latitude
        self.longitude = longitude
        self.isCurrentLocation = isCurrentLocation
        self.distanceInMeters = distanceInMeters
    }
}

private final class LocationSearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    var onResults: (([MKLocalSearchCompletion]) -> Void)?
    var onError: ((Error) -> Void)?

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onResults?(completer.results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onError?(error)
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
