//
//  PulseApp.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import SwiftUI
import SwiftData

@main
struct PulseApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .modelContainer(for: [Moment.self])
        }
    }
}
