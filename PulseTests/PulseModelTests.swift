//
//  PulseModelTests.swift
//  PulseTests
//
//  Created by Maury Alamin on 5/16/25.
//

import Foundation
import XCTest
import SwiftData
@testable import Pulse

@MainActor
final class PulseModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Moment.self, Urge.self, Tag.self, configurations: config)
        context = container.mainContext
    }

    func testSeedingUrges() throws {
        XCTAssertTrue(try context.fetch(FetchDescriptor<Urge>()).isEmpty)

        for urge in UrgeDefaults.builtIn {
            context.insert(urge)
        }
        try context.save()

        let urges = try context.fetch(FetchDescriptor<Urge>())
        XCTAssertEqual(urges.count, UrgeDefaults.builtIn.count)
    }

    func testMomentCreation() throws {
        let urge = Urge(name: "Test Urge", colorHex: "#123456")
        context.insert(urge)

        let moment = Moment(
            timestamp: Date(),
            urge: urge,
            intensity: 4,
            gaveIn: false,
            note: "Sample note",
            tags: []
        )
        context.insert(moment)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Moment>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.urge.name, "Test Urge")
        XCTAssertEqual(fetched.first?.intensity, 4)
        XCTAssertEqual(fetched.first?.gaveIn, false)
    }

    func testTagAssignmentToMoment() throws {
        let urge = Urge(name: "Scrolling", colorHex: "#445566")
        let tag = Tag(name: "After Work")
        context.insert(urge)
        context.insert(tag)

        let moment = Moment(
            timestamp: Date(),
            urge: urge,
            intensity: 2,
            gaveIn: true,
            note: nil,
            tags: [tag]
        )
        context.insert(moment)
        try context.save()

        let results = try context.fetch(FetchDescriptor<Moment>())
        XCTAssertEqual(results.first?.tags?.first?.name, "After Work")
    }
}
