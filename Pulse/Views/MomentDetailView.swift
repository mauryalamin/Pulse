//
//  MomentDetailView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/12/25.
//

import SwiftUI

struct MomentDetailView: View {
    
    let moment: Moment
    
    var body: some View {
        List {
            Section(header: Text("Urge")) {
                HStack {
                    Circle()
                        .fill(Color(hex: moment.urge.colorHex) ?? .gray)
                        .frame(width: 12, height: 12)
                    Text(moment.urge.name)
                }
            }
            
            Section(header: Text("Intensity")) {
                Text("\(moment.intensity)")
            }
            
            Section(header: Text("Gave In?")) {
                Text(moment.gaveIn ? "Yes" : "No")
            }
            
            if let note = moment.note {
                Section(header: Text("Note")) {
                    Text(note)
                }
            }
            
            Section(header: Text("Logged At")) {
                Text(moment.timestamp.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .navigationTitle("Logged Moment")
    }
    
}

#Preview {
    NavigationStack {
        MomentDetailView(moment: Moment(urge: Urge(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 5, gaveIn: false))
    }
}
