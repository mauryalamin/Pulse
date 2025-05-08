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
                TextField("Vice", text: $moment.vice)
                Button("Log Moment") {
                
                    
                    dismiss()
                }
                
            }
            .navigationTitle("Log Moment")
        }
    }
}

#Preview {
    UpdateMomentView(moment: Moment(vice: "Drugs", intensity: 5, gaveIn: false))
}
