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
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor, lineWidth: isSelected ? 2 : 0)
                    )
                
                //                .stroke(Color(UIColor.lightGray), lineWidth: 10)
                //                .fill(Color.white)
                //                .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                //                .font(.title3)
                //                .fontWeight(.semibold)
                //                .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    IntensityButtonView(number: 1, isSelected: false, action: {})
}
