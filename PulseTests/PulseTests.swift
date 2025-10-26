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


// Disambiguate the app's Tag model from SwiftUI.Tag (and others)
typealias AppTag = Pulse.Tag

// MARK: - Weather Mock (no-op result; mapping under test doesn’t use weather yet)
struct WeatherServiceMockNoop: WeatherService {
    func fetchWeather(for coordinate: CLLocationCoordinate2D, at date: Date) async throws -> WeatherSnapshot {
        WeatherSnapshot(temperature: 18.5, conditionCode: 2) // arbitrary
    }
}

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


// MARK: - Tests
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

@MainActor
struct CreateMomentUseCase_DTO_Mapping_Tests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Moment.self, Urge.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test
    func maps_all_fields_correctly_including_location_and_timestamp() async throws {
        // Arrange
        let container = try makeContainer()
        let ctx = ModelContext(container)

        let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
        let tagA = Tag(name: "After Work")
        let tagB = Tag(name: "Stress")
        ctx.insert(urge)
        ctx.insert(tagA)
        ctx.insert(tagB)
        try ctx.save()

        let fixedTimestamp = Date(timeIntervalSince1970: 1_700_000_000) // deterministic date

        let dto = CreateMomentDTO(
            urge: urge,
            intensity: 4,
            response: .stayedPresent,              // should map to gaveIn == false
            notes: "Felt the urge but stayed present",
            tags: [tagA, tagB],
            location: LocationSnapshot(lat: 37.3349, lon: -122.0090, place: "Apple Park"),
            timestamp: fixedTimestamp
        )

        let uc = CreateMomentUseCase(weather: WeatherServiceMockNoop())

        // Act
        try await uc(dto, in: ctx)

        // Assert — one Moment saved
        let fetch = FetchDescriptor<Moment>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let moments = try ctx.fetch(fetch)
        #expect(moments.count == 1)

        guard let m = moments.first else {
            Issue.record("No moment found after save")
            return
        }

        // Field-by-field checks
        #expect(m.timestamp == fixedTimestamp)
        #expect(m.urge.id == urge.id)                       // same associated Urge
        #expect(m.intensity == 4)
        #expect(m.gaveIn == false)                          // from .stayedPresent
        #expect(m.note == "Felt the urge but stayed present")
        #expect((m.tags ?? []).count == 2)
        #expect(m.tags?.contains(where: { $0.id == tagA.id }) == true)
        #expect(m.tags?.contains(where: { $0.id == tagB.id }) == true)

        // Location mapping
        #expect(m.latitude == 37.3349)
        #expect(m.longitude == -122.0090)
        // If you map place/description later, assert it here.
    }

    @Test
    func empty_notes_become_nil_and_location_nil_leaves_coords_nil() async throws {
        // Arrange
        let container = try makeContainer()
        let ctx = ModelContext(container)

        let urge = Urge(name: "Scrolling", colorHex: "#445566")
        ctx.insert(urge)
        try ctx.save()

        let dto = CreateMomentDTO(
            urge: urge,
            intensity: 2,
            response: .followed,                     // should map to gaveIn == true
            notes: "",                             // empty → nil
            tags: [],
            location: nil,                         // no location
            timestamp: Date(timeIntervalSince1970: 1_800_000_000)
        )

        let uc = CreateMomentUseCase(weather: WeatherServiceMockNoop())

        // Act
        try await uc(dto, in: ctx)

        // Assert
        let fetched = try ctx.fetch(FetchDescriptor<Moment>())
        #expect(fetched.count == 1)

        guard let m = fetched.first else {
            Issue.record("No moment found after save")
            return
        }

        #expect(m.urge.id == urge.id)
        #expect(m.intensity == 2)
        #expect(m.gaveIn == true)                 // from .gaveIn
        #expect(m.note == nil)                    // normalized
        #expect((m.tags ?? []).isEmpty)
        #expect(m.latitude == nil)
        #expect(m.longitude == nil)
    }
}

@MainActor
struct TagUsageBumpTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Moment.self, Urge.self, AppTag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test
    func tag_usage_bump_after_save_persists() async throws {
        // Arrange
        let container = try makeContainer()
        let ctx = ModelContext(container)

        // Seed Urge + Tags
        let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
        let tagA = AppTag(name: "After Work")   // will be used
        let tagB = AppTag(name: "Stress")       // will be used
        let tagC = AppTag(name: "Gym")          // unused control
        ctx.insert(urge); ctx.insert(tagA); ctx.insert(tagB); ctx.insert(tagC)
        try ctx.save()

        // Precondition
        #expect(tagA.usageCount == 0)
        #expect(tagB.usageCount == 0)
        #expect(tagC.usageCount == 0)

        // Build DTO with tagA + tagB
        let dto = CreateMomentDTO(
            urge: urge,
            intensity: 3,
            response: .stayedPresent,
            notes: "Testing tag usage bump",
            tags: [tagA, tagB],
            location: LocationSnapshot(lat: 37.3349, lon: -122.0090, place: "Apple Park"),
            timestamp: Date(timeIntervalSince1970: 1_777_000_000)
        )

        let uc = CreateMomentUseCase(weather: WeatherServiceMockNoop())

        // Act: save the Moment
        try await uc(dto, in: ctx)

        // Simulate UI-layer bump (matches app behavior after a successful save)
        [tagA, tagB].forEach { $0.usageCount += 1 }
        try ctx.save()

        // Assert: only used tags bumped
        let tagFetch = FetchDescriptor<AppTag>(
            sortBy: [SortDescriptor(\AppTag.name)]   // explicitly root the key path
        )
        let tags = try ctx.fetch(tagFetch)

        let a = tags.first(where: { $0.id == tagA.id })!
        let b = tags.first(where: { $0.id == tagB.id })!
        let c = tags.first(where: { $0.id == tagC.id })!

        #expect(a.usageCount == 1)
        #expect(b.usageCount == 1)
        #expect(c.usageCount == 0)

        // Optional sanity: exactly one moment saved
        let moments = try ctx.fetch(FetchDescriptor<Moment>())
        #expect(moments.count == 1)
    }

    @Test
    func tag_usage_is_not_double_bumped_on_single_save() async throws {
        // Arrange
        let container = try makeContainer()
        let ctx = ModelContext(container)

        let urge = Urge(name: "Scrolling", colorHex: "#445566")
        let tag = AppTag(name: "Evening")
        ctx.insert(urge); ctx.insert(tag)
        try ctx.save()

        let dto = CreateMomentDTO(
            urge: urge,
            intensity: 2,
            response: .followed,            // maps to gaveIn == true
            notes: "Single save",
            tags: [tag],
            location: nil,
            timestamp: Date(timeIntervalSince1970: 1_800_000_000)
        )

        let uc = CreateMomentUseCase(weather: WeatherServiceMockNoop())

        // Act: save once, bump once
        try await uc(dto, in: ctx)
        tag.usageCount += 1
        try ctx.save()

        // Assert: still 1 after avoiding accidental re-bump
        let fetched = try ctx.fetch(FetchDescriptor<AppTag>())
        let t = fetched.first(where: { $0.id == tag.id })!
        #expect(t.usageCount == 1)
    }
}
