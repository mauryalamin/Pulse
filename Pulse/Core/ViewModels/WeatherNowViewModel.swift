//
//  WeatherNowViewModel.swift
//  Pulse
//
//  Created by Maury Alamin on 10/22/25.
//

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class WeatherNowViewModel {
    // Inputs
    private let weather: WeatherService
    private let location: LocationManager

    // Output for the row
    var state: WeatherNowState = .loading

    // Debounce task
    private var pending: Task<Void, Never>?

    init(weather: WeatherService, location: LocationManager) {
        self.weather = weather
        self.location = location
    }

    // Call on appear
    func start() {
        // Initial kick
        refreshNow()
    }

    // Call when location/authorization changes
    func locationDidChange() {
        pending?.cancel()
        pending = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(750))
            self?.refreshNow()
        }
    }

    // MARK: - Core

    private func refreshNow() {
        // Authorization guard
        let isAuthorized = location.authorizationStatus == .authorizedWhenInUse
                        || location.authorizationStatus == .authorizedAlways
        guard isAuthorized else {
            state = .failed("No permission")
            return
        }

        // Coordinate guard
        guard let coord = location.location?.coordinate else {
            state = .loading
            return
        }

        state = .loading
        Task { [weak self] in
            guard let self else { return }
            do {
                let snap = try await weather.fetchWeather(for: coord, at: Date())
                // Loaded
                await MainActor.run { self.state = .loaded(snap) }
            } catch {
                await MainActor.run { self.state = .failed("Network") }
            }
        }
    }
}
