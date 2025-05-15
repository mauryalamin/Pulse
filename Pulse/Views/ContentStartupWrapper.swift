//
//  ContentStartupWrapper.swift
//  Pulse
//
//  Created by Maury Alamin on 5/15/25.
//

import SwiftUI
import SwiftData

struct ContentStartupWrapper: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var urges: [Urge]
    
    var body: some View {
        HomeView()
            .task {
                if urges.isEmpty {
                    for urge in UrgeDefaults.builtIn {
                        modelContext.insert(urge)
                    }
                    try? modelContext.save()
                }
            }
    }
}

#Preview {
    ContentStartupWrapper()
}
