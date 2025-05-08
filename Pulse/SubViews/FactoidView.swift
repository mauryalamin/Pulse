//
//  FactoidView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/8/25.
//

import SwiftUI

struct FactoidView: View {
    
    var icon: String
    var numbers: Int
    var typeLabel: String
    
    var body: some View {
        VStack (alignment: .leading){
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                Text("\(numbers)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
            }
            Text(typeLabel)
                .font(.caption2)
        }
    }
}

#Preview {
    FactoidView(icon: "list.bullet", numbers: 24, typeLabel: "Moments Captured")
}
