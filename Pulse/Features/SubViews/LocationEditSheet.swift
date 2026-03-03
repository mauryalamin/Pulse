//
//  LocationEditSheet.swift
//  Pulse
//
//  Created by Codex on 3/3/26.
//

import SwiftUI
import MapKit
import UIKit

struct LocationEditSheet: View {
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
    LocationEditSheet(
        initialLocationDescription: "Chicago, IL",
        initialLatitude: 41.8781,
        initialLongitude: -87.6298,
        onSave: { _, _, _ in }
    )
}
