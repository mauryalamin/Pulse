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

// MARK: - Weather Mocks

/// Weather used when the mapping test doesn't care about weather content.
struct WeatherServiceMockNoop: WeatherService {
    func fetchWeather(for coordinate: CLLocationCoordinate2D, at date: Date) async throws -> WeatherSnapshot {
        WeatherSnapshot(temperature: 18.5, conditionCode: 2) // arbitrary
    }
}

/// Delayed weather mock to keep the use case busy long enough to simulate a double-tap.
struct WeatherServiceMockDelayed: WeatherService {
    let delay: Duration
    func fetchWeather(for coordinate: CLLocationCoordinate2D, at date: Date) async throws -> WeatherSnapshot {
        try? await Task.sleep(for: delay)
        return WeatherSnapshot(temperature: 21.0, conditionCode: 2)
    }
}

// MARK: - Shared helpers

@MainActor
private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
        for: Moment.self, Urge.self, AppTag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}

// MARK: - ViewModel logic

@MainActor
struct LogMomentViewModelTests {
    
    // canSave state machine (no reentrancy)
    @Test
    func canSave_transitions_correctly() async throws {
        let container = try makeContainer()
        let ctx = ModelContext(container)
        
        let vm = LogMomentViewModel(
            modelContext: ctx,
            createMoment: CreateMomentUseCase(weather: WeatherServiceMockNoop()),
            location: LocationManager.shared
        )
        
        let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
        
        // 1) Nothing selected
        #expect(vm.canSave == false)
        
        // 2) Urge only
        vm.selectedUrge = urge
        #expect(vm.canSave == false)
        
        // 3) Intensity only
        vm.selectedUrge = nil
        vm.intensity = 3
        #expect(vm.canSave == false)
        
        // 4) Urge + intensity
        vm.selectedUrge = urge
        vm.intensity = 3
        #expect(vm.canSave == true)
    }
    
    // Double-tap guard: second save ignored; only one Moment persisted
    @Test
    func doubleTapGuard_persists_once() async throws {
        let container = try makeContainer()
        let ctx = ModelContext(container)
        
        let vm = LogMomentViewModel(
            modelContext: ctx,
            createMoment: CreateMomentUseCase(weather: WeatherServiceMockDelayed(delay: .milliseconds(250))),
            location: LocationManager.shared
        )
        
        // Seed required urge
        let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
        ctx.insert(urge)
        try ctx.save()
        
        vm.selectedUrge = urge
        vm.intensity = 3
        #expect(vm.canSave == true)
        
        // Start save #1 (main-actor task)
        let t1 = Task { @MainActor in await vm.save() }
        
        // Let save() flip isSaving = true
        await Task.yield()
        #expect(vm.canSave == false)
        
        // Initiate a second save while first is in-flight → should be ignored
        await vm.save()
        
        // Wait for #1 to finish
        _ = await t1.value
        
        // Exactly one moment should exist
        let fetch = FetchDescriptor<Moment>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let moments = try ctx.fetch(fetch)
        #expect(moments.count == 1)
        
        // After completion (and with fields still valid) canSave becomes true again
        #expect(vm.canSave == true)
    }
}

// MARK: - Use case (DTO → Model mapping)

@MainActor
struct CreateMomentUseCase_MappingTests {
    
    @Test
    func maps_all_fields_correctly_including_location_and_timestamp() async throws {
        let container = try makeContainer()
        let ctx = ModelContext(container)
        
        // Seed entities
        let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
        let tagA = AppTag(name: "After Work")
        let tagB = AppTag(name: "Stress")
        ctx.insert(urge); ctx.insert(tagA); ctx.insert(tagB)
        try ctx.save()
        
        let fixedTimestamp = Date(timeIntervalSince1970: 1_700_000_000)
        
        let dto = CreateMomentDTO(
            urge: urge,
            intensity: 4,
            response: .stayedPresent,           // → gaveIn == false
            notes: "Felt the urge but stayed present",
            tags: [tagA, tagB],
            location: LocationSnapshot(lat: 37.3349, lon: -122.0090, place: "Apple Park"),
            timestamp: fixedTimestamp
        )
        
        let uc = CreateMomentUseCase(weather: WeatherServiceMockNoop())
        
        try await uc(dto, in: ctx)
        
        let fetch = FetchDescriptor<Moment>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let moments = try ctx.fetch(fetch)
        #expect(moments.count == 1)
        
        guard let m = moments.first else {
            Issue.record("No moment found after save")
            return
        }
        
        #expect(m.timestamp == fixedTimestamp)
        #expect(m.urge.id == urge.id)
        #expect(m.intensity == 4)
        #expect(m.gaveIn == false) // from .stayedPresent
        #expect(m.note == "Felt the urge but stayed present")
        #expect(m.tags?.contains(where: { $0.id == tagA.id }) == true)
        #expect(m.tags?.contains(where: { $0.id == tagB.id }) == true)
        #expect(m.latitude == 37.3349)
        #expect(m.longitude == -122.0090)
    }
    
    @Test
    func empty_notes_become_nil_and_location_nil_leaves_coords_nil() async throws {
        let container = try makeContainer()
        let ctx = ModelContext(container)
        
        let urge = Urge(name: "Scrolling", colorHex: "#445566")
        ctx.insert(urge)
        try ctx.save()
        
        let dto = CreateMomentDTO(
            urge: urge,
            intensity: 2,
            response: .followed,               // → gaveIn == true
            notes: "",                         // empty → nil
            tags: [],
            location: nil,                     // no location
            timestamp: Date(timeIntervalSince1970: 1_800_000_000)
        )
        
        let uc = CreateMomentUseCase(weather: WeatherServiceMockNoop())
        
        try await uc(dto, in: ctx)
        
        let fetched = try ctx.fetch(FetchDescriptor<Moment>())
        #expect(fetched.count == 1)
        
        guard let m = fetched.first else {
            Issue.record("No moment found after save")
            return
        }
        
        #expect(m.urge.id == urge.id)
        #expect(m.intensity == 2)
        #expect(m.gaveIn == true)
        #expect(m.note == nil)                 // normalized
        #expect((m.tags ?? []).isEmpty)
        #expect(m.latitude == nil)
        #expect(m.longitude == nil)
    }
}

// MARK: - Tag usage bump (UI-layer behavior mirrored in tests)

@MainActor
struct TagUsageBumpTests {
    
    @Test
    func tag_usage_bump_after_save_persists() async throws {
        let container = try makeContainer()
        let ctx = ModelContext(container)
        
        let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
        let tagA = AppTag(name: "After Work")   // used
        let tagB = AppTag(name: "Stress")       // used
        let tagC = AppTag(name: "Gym")          // control (unused)
        ctx.insert(urge); ctx.insert(tagA); ctx.insert(tagB); ctx.insert(tagC)
        try ctx.save()
        
        #expect(tagA.usageCount == 0)
        #expect(tagB.usageCount == 0)
        #expect(tagC.usageCount == 0)
        
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
        try await uc(dto, in: ctx)
        
        // Simulate UI bump (matches app post-save behavior)
        [tagA, tagB].forEach { $0.usageCount += 1 }
        try ctx.save()
        
        // Assert
        let tagFetch = FetchDescriptor<AppTag>(sortBy: [SortDescriptor(\AppTag.name)])
        let tags = try ctx.fetch(tagFetch)
        
        let a = tags.first(where: { $0.id == tagA.id })!
        let b = tags.first(where: { $0.id == tagB.id })!
        let c = tags.first(where: { $0.id == tagC.id })!
        
        #expect(a.usageCount == 1)
        #expect(b.usageCount == 1)
        #expect(c.usageCount == 0)
        
        // Sanity: exactly one moment saved
        let moments = try ctx.fetch(FetchDescriptor<Moment>())
        #expect(moments.count == 1)
    }
    
    @Test
    func tag_usage_is_not_double_bumped_on_single_save() async throws {
        let container = try makeContainer()
        let ctx = ModelContext(container)
        
        let urge = Urge(name: "Scrolling", colorHex: "#445566")
        let tag = AppTag(name: "Evening")
        ctx.insert(urge); ctx.insert(tag)
        try ctx.save()
        
        let dto = CreateMomentDTO(
            urge: urge,
            intensity: 2,
            response: .followed, // → gaveIn == true
            notes: "Single save",
            tags: [tag],
            location: nil,
            timestamp: Date(timeIntervalSince1970: 1_800_000_000)
        )
        
        let uc = CreateMomentUseCase(weather: WeatherServiceMockNoop())
        
        try await uc(dto, in: ctx)
        tag.usageCount += 1
        try ctx.save()
        
        let fetched = try ctx.fetch(FetchDescriptor<AppTag>())
        let t = fetched.first(where: { $0.id == tag.id })!
        #expect(t.usageCount == 1)
    }
}

@MainActor
struct EditMomentViewModelTests {
    
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Moment.self, Urge.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
    
    @Test
    func editing_urge_updates_existing_moment_reference() throws {
        // Arrange: in-memory SwiftData stack
        let container = try makeContainer()
        let ctx = ModelContext(container)
        
        let originalUrge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
        let newUrge      = Urge(name: "Scrolling", colorHex: "#445566")
        
        let moment = Moment(
            timestamp: Date(),
            urge: originalUrge,
            intensity: 3,
            gaveIn: false,
            note: "Before editing"
        )
        
        ctx.insert(originalUrge)
        ctx.insert(newUrge)
        ctx.insert(moment)
        try ctx.save()
        
        // Sanity check
        #expect(moment.urge.id == originalUrge.id)
        
        // Act: edit via the view model
        let vm = EditMomentViewModel(moment: moment)
        #expect(vm.selectedUrge?.id == originalUrge.id)
        
        vm.selectedUrge = newUrge
        try vm.save(in: ctx)
        
        // Assert: only one Moment, now pointing at the new urge
        let fetch = FetchDescriptor<Moment>()
        let moments = try ctx.fetch(fetch)
        #expect(moments.count == 1)
        
        guard let updated = moments.first else {
            Issue.record("No Moment fetched after editing")
            return
        }
        
        #expect(updated.urge.id == newUrge.id)
        #expect(updated.intensity == 3)
        #expect(updated.gaveIn == false)
        #expect(updated.note == "Before editing")
    }
    
    @Test
    func save_updates_intensity_and_persists() throws {
        // Arrange: in-memory container + context
        let container = try makeContainer()
        let ctx = ModelContext(container)
        
        // Seed an Urge and a Moment with a known intensity + timestamp
        let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
        ctx.insert(urge)
        
        let fixedTimestamp = Date(timeIntervalSince1970: 1_800_000_000)
        
        let moment = Moment(
            timestamp: fixedTimestamp,
            urge: urge,
            intensity: 2,       // start at 2
            gaveIn: false,
            note: "Original note",
            tags: []
        )
        ctx.insert(moment)
        try ctx.save()
        
        // Build the ViewModel from that Moment
        let vm = EditMomentViewModel(moment: moment)
        
        // Precondition: VM reflects the original intensity
        #expect(vm.intensity == 2)
        
        // Act: change intensity and save back to SwiftData
        vm.intensity = 5
        try vm.save(in: ctx)
        
        // Assert: refetch by the fixed timestamp
        let fetch = FetchDescriptor<Moment>(
            predicate: #Predicate { $0.timestamp == fixedTimestamp }
        )
        let results = try ctx.fetch(fetch)
        #expect(results.count == 1)
        #expect(results.first?.intensity == 5)
        
        // And the in-memory instance should now reflect 5 as well
        #expect(moment.intensity == 5)
    }
    
    @Test
    func saving_updates_response_on_moment() throws {
        // Arrange: in-memory store + seed a Moment
        let container = try makeContainer()
        let ctx = ModelContext(container)

        let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
        ctx.insert(urge)

        let moment = Moment(
            timestamp: .now,
            urge: urge,
            intensity: 3,
            gaveIn: false,            // starts as "Stayed Present"
            note: "Original note",
            tags: []
        )
        ctx.insert(moment)
        try ctx.save()

        // Precondition
        #expect(moment.gaveIn == false)

        // Act: edit response → .followed and save
        let vm = EditMomentViewModel(moment: moment)
        #expect(vm.response == .stayedPresent)   // mirrors gaveIn == false

        vm.response = .followed                 // user flips the toggle
        try vm.save(in: ctx)

        // Assert: fetched Moment has updated gaveIn
        let fetch = try ctx.fetch(FetchDescriptor<Moment>())
        #expect(fetch.count == 1)

        guard let updated = fetch.first else {
            Issue.record("No Moment found after save")
            return
        }

        #expect(updated.gaveIn == true)
    }
}

