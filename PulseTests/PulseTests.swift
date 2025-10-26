//
//  PulseTests.swift
//  PulseTests
//
//  Created by Maury Alamin on 5/7/25.
//

import Testing
import SwiftData
import CoreLocation
@testable import Pulse

/// Instant, successful weather mock (used in the simple canSave test)
struct WeatherServiceMock: WeatherService {
    func fetchWeather(for coordinate: CLLocationCoordinate2D, at date: Date) async throws -> WeatherSnapshot {
        WeatherSnapshot(temperature: 21.0, conditionCode: 2)
    }
}

/// Delayed weather mock to keep the use case in-flight long enough to simulate a double-tap.
struct WeatherServiceMockDelayed: WeatherService {
    let delay: Duration
    func fetchWeather(for coordinate: CLLocationCoordinate2D, at date: Date) async throws -> WeatherSnapshot {
        try? await Task.sleep(for: delay)
        return WeatherSnapshot(temperature: 21.0, conditionCode: 2)
    }
}

// If you later abstract LocationManager with a protocol:
final class LocationManagerFake {
    var currentPlacename: String?
    func snapshot() async -> LocationSnapshot? {
        // Return a fixed snapshot (or nil)
        nil
    }
}

struct CreateMomentUseCaseTests {

    @Test @MainActor
    func savingMomentPersists() async throws {
        let container = try ModelContainer(
            for: Moment.self, Urge.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let ctx = ModelContext(container)
        let useCase = CreateMomentUseCase(weather: WeatherServiceMock())

        let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
        ctx.insert(urge)

        let dto = CreateMomentDTO(
            urge: urge,
            intensity: 3,
            response: .stayedPresent,
            notes: "quick note",
            tags: [],
            location: nil,
            timestamp: .now
        )

        try await useCase(dto, in: ctx)

        let fetch = FetchDescriptor<Moment>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let moments = try ctx.fetch(fetch)

        #expect(moments.count == 1)
        #expect(moments.first?.intensity == 3)
        #expect(moments.first?.gaveIn == false)
        #expect(moments.first?.urge.name == "Alcohol")
    }
}

// MARK: - Tests

@MainActor
struct LogMomentViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Moment.self, Urge.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    // 1) canSave transitions (no reentrancy involved)
    @Test
    func canSave_transitions_correctly() async throws {
        let container = try makeContainer()
        let ctx = ModelContext(container)

        let vm = LogMomentViewModel(
            modelContext: ctx,
            createMoment: CreateMomentUseCase(weather: WeatherServiceMock()),
            location: LocationManager.shared
        )

        let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")

        #expect(vm.canSave == false)  // nothing selected
        vm.selectedUrge = urge
        #expect(vm.canSave == false)  // urge only
        vm.selectedUrge = nil
        vm.intensity = 3
        #expect(vm.canSave == false)  // intensity only
        vm.selectedUrge = urge
        vm.intensity = 3
        #expect(vm.canSave == true)   // urge + intensity
    }

    // 2) Double-tap guard: second save ignored; only one Moment persisted
    @Test
    func doubleTapGuard_preventsSecondSave_andPersistsOnce() async throws {
        let container = try makeContainer()
        let ctx = ModelContext(container)

        // Use the real UC with a delayed weather fetch to keep save() busy briefly.
        let vm = LogMomentViewModel(
            modelContext: ctx,
            createMoment: CreateMomentUseCase(weather: WeatherServiceMockDelayed(delay: .milliseconds(250))),
            location: LocationManager.shared
        )

        // Seed a required urge
        let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
        ctx.insert(urge)
        try ctx.save()

        // Set required fields
        vm.selectedUrge = urge
        vm.intensity = 3
        #expect(vm.canSave == true)

        // Start save #1
        let t1 = Task { @MainActor in await vm.save() }

        // Give save() a chance to flip isSaving = true
        await Task.yield()

        // While first save is in-flight, guard should make canSave false
        #expect(vm.canSave == false)

        // Try save #2 (should be ignored)
        await vm.save()

        // Wait for first to finish
        _ = await t1.value

        // Verify exactly one Moment exists
        let fetch = FetchDescriptor<Moment>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let moments = try ctx.fetch(fetch)
        #expect(moments.count == 1)

        // After completion, with fields intact, canSave becomes true again
        #expect(vm.canSave == true)
    }
}

struct LogMomentNoDoubleSaveTests_TaskVariant {

    @Test @MainActor
    func twoSavesBackToBack_onlyOnePersists() async throws {
        let container = try ModelContainer(
            for: Moment.self, Urge.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let ctx = ModelContext(container)

        let vm = LogMomentViewModel(
            modelContext: ctx,
            createMoment: CreateMomentUseCase(weather: WeatherServiceMock()),
            location: LocationManager.shared
        )

        // Valid selections
        let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
        ctx.insert(urge)
        vm.selectedUrge = urge
        vm.intensity = 3

        // Kick off two tasks on MainActor (no Sendable violation)
        let t1 = Task { @MainActor in await vm.save() }
        let t2 = Task { @MainActor in await vm.save() }

        _ = await (t1.value, t2.value)

        let fetch = FetchDescriptor<Moment>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let moments = try ctx.fetch(fetch)
        #expect(moments.count == 1)
    }
}

struct CreateMomentDTO_MappingTests {

    @Test @MainActor
    func dto_fields_map_into_Moment_correctly() async throws {
        // In-memory store
        let container = try ModelContainer(
            for: Moment.self, Urge.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let ctx = ModelContext(container)
        let useCase = CreateMomentUseCase(weather: WeatherServiceMock())

        // Given app data to attach
        let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
        let tag  = Tag(name: "After Work")
        ctx.insert(urge)
        ctx.insert(tag)

        // Stable timestamp to assert exact equality
        let fixedDate = Date(timeIntervalSince1970: 1_726_000_000)

        // If your LocationSnapshot type is available to tests, use it directly:
        // Otherwise, set `location: nil` and drop the lat/lon expectations below.
        let loc = LocationSnapshot(lat: 37.3317, lon: -122.0301, place: "Cupertino")

        // When: build DTO and run the use case
        let dto = CreateMomentDTO(
            urge: urge,
            intensity: 4,
            response: .stayedPresent,     // -> should map to gaveIn == false
            notes: "Felt strong urge after work",
            tags: [tag],
            location: loc,
            timestamp: fixedDate
        )

        try await useCase(dto, in: ctx)

        // Then: fetch and assert field-by-field mapping
        let fetch = FetchDescriptor<Moment>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let moments = try ctx.fetch(fetch)

        #expect(moments.count == 1)
        let m = try #require(moments.first)

        // Core fields
        #expect(m.urge.id == urge.id)
        #expect(m.intensity == 4)
        #expect(m.gaveIn == false)                        // stayedPresent -> false
        #expect(m.note == "Felt strong urge after work")
        #expect(m.timestamp == fixedDate)

        // Tags
        let names = (m.tags ?? []).map(\.name)
        #expect(names == ["After Work"])

        // Location mapping (only if your model stores these)
        #expect(m.latitude == 37.3317)
        #expect(m.longitude == -122.0301)
    }
}

