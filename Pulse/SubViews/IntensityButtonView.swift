//
//  IntensityButtonView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/9/25.
//

import SwiftUI

struct IntensityButtonView: View {
    
    var number: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button (action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.pulseBlue : Color(UIColor.systemGray5), lineWidth: 4)
                    )
                
                Text("\(number)")
                    .font(.headline)
                    .fontWeight(isSelected ? .bold : .semibold)
                    .foregroundColor(isSelected ? .pulseBlue : Color.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    IntensityButtonView(number: 1, isSelected: false, action: {})
}
