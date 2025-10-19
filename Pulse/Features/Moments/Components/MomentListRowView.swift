//
//  MomentListRowView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/8/25.
//

import SwiftUI

struct MomentListRowView: View {
    
    let moment: Moment
    
    var body: some View {
        HStack {
            VStack (alignment: .leading, spacing: 6) {
                // Text(moment.timestamp.formatted(date: .abbreviated, time: .shortened))
                Text(moment.timestamp.smartRelativeDescription())
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)
                    .padding(.vertical, 4)
                
                    Text(moment.urge.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    IntensityBarView(intensity: moment.intensity)
            }
            Spacer()
            VStack {
                ResponseTypeTagView(iGaveIn: moment.gaveIn)
            }
        }
        
    }
}

#Preview ("Stayed Present"){
    MomentListRowView(moment: Moment(timestamp: .now, urge: Urge(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 4, gaveIn: false))
}

#Preview ("Gave In"){
    MomentListRowView(moment: Moment(timestamp: .now, urge: Urge(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 4, gaveIn: true))
}
