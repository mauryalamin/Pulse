//
//  Persistence.swift
//  Pulse
//
//  Created by Maury Alamin on 10/28/25.
//

import SwiftUI
import SwiftData

enum Persistence {
    static let shared: ModelContainer = {
        do {
            // ~/Library/Application Support/Pulse.store
            let appSupport = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let url = appSupport.appending(path: "Pulse.store")

            let schema = Schema([Moment.self, Urge.self, Tag.self])
            let config = ModelConfiguration(url: url)

            let container = try ModelContainer(for: schema, configurations: [config])

            // ✅ URL is non-optional now
            let path = container.configurations.first!.url.path
            print("📦 SwiftData store URL:", path)

            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
