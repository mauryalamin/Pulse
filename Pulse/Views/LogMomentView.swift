//
//  LogMomentView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import SwiftUI
import SwiftData

struct LogMomentView: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    
    @State private var moment: Moment?
    @State private var vice: String = ""
    @State private var timestamp: Date = .now
    @State private var intensity: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                TextField("Vice", text: $vice)
                TextField("Intensity", text: $intensity)
                Button("Log Moment") {
                    
                    let moment = Moment(timestamp: timestamp, vice: Vice(name: "Alcohol", colorHex: "#8B3A3A"), intensity: Int(intensity) ?? 0, gaveIn: false, note: nil)
                    context.insert(moment)
                    
                    dismiss()
                }
                
            }
            .navigationTitle("Log Moment")
        }
    }
}

#Preview {
    LogMomentView()
}
