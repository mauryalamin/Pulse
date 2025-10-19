//
//  IntensityBarView.swift
//  Pulse
//
//  Created by Maury Alamin on 10/18/25.
//

import SwiftUI

struct IntensityBarView: View {
    var intensity: Int
    
    var body: some View {
        HStack (alignment: .center) {
            RoundedRectangle (cornerRadius: 2)
                .foregroundColor(Color(UIColor.systemGray4))
                .frame(width: 150, height: 16)
            ZStack (alignment: .center){
                Image(systemName: "circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color(UIColor.systemGray4))
                Text("\(intensity)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    
            }
        }
    }
}

#Preview {
    IntensityBarView(intensity: 4)
}

