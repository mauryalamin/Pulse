//
//  IntensityButtonView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/9/25.
//

import SwiftUI

struct IntensityButtonView: View {
    
    var intensity: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(UIColor.lightGray), lineWidth: 10)
                .fill(Color.white)
                .frame(width: 32, height: 32)
            Text("\(intensity)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    IntensityButtonView(intensity: 1)
}
