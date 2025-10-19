//
//  IntensityBarView.swift
//  Pulse
//
//  Created by Maury Alamin on 10/18/25.
//

import SwiftUI

struct IntensityBarView: View {
    let intensity: Int
    let hexColor: String
    var height: CGFloat = 12
    var stepWidth: CGFloat = 30
    var fallbackColor: Color = .gray
    
    private let brightness = [0.4, 0.3, 0.2, 0.1, 0.0]   // 0.0 = no change
    private let saturation = [0.6, 0.7, 0.8, 0.9, 1.0]   // 1.0 = no change
    
    var body: some View {
        // Clamp to your allowed range (1...5) so it never crashes
        let count = min(max(intensity, 1), 5)
        let base = Color(hex: hexColor) ?? fallbackColor
        
        HStack (alignment: .center) {
            ZStack (alignment: .leading) {
                Rectangle()
                    .frame(width: stepWidth * 5, height: height)
                    .foregroundColor(Color(UIColor.systemGray5))
                
                HStack(spacing: 0) {
                    ForEach(0..<count, id: \.self) { i in
                        Rectangle()
                            .foregroundStyle(base)
                            .brightness(brightness[i])
                            .saturation(saturation[i])
                            .frame(width: stepWidth, height: height)
                    }
                }
                // Total width is exactly count * 50
                .frame(width: CGFloat(count) * stepWidth, height: height, alignment: .leading)
                .accessibilityLabel("Intensity \(count) of 5")
            }
            
            // Intensity Number
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
    IntensityBarView(intensity: 4, hexColor: "#4285F4")
}

