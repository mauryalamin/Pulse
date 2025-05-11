//
//  UpdateMomentView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import SwiftUI

struct UpdateMomentView: View {
    @Environment(\.dismiss) var dismiss
    
    @Bindable var moment: Moment
    
    var body: some View {
        NavigationStack {
            List {
                TextField("Urge", text: $moment.urge.name)
                Button("Log Moment") {
                
                    
                    dismiss()
                }
                
            }
            .navigationTitle("Log Moment")
        }
    }
}

#Preview {
    UpdateMomentView(moment: Moment(urge: Urge(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 5, gaveIn: false))
}
