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
    @Query private var tags: [Tag]
    
    var body: some View {
        HomeView()
            .task {
                if urges.isEmpty {
                    for urge in UrgeDefaults.builtIn {
                        modelContext.insert(urge)
                    }
                }
                
                if tags.isEmpty {
                    for tag in TagDefaults.builtIn {
                        modelContext.insert(tag)
                    }
                }
                
                if urges.isEmpty || tags.isEmpty {
                    try? modelContext.save()
                }
            }
    }
}

#Preview {
    ContentStartupWrapper()
}
