//
//  IntensityButtonView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/9/25.
//

import SwiftUI

struct IntensityButtonView: View {
    // Inputs
    var number: Int
    let isSelected: Bool
    let isFilled: Bool
    let baseHex: String?
    let action: () -> Void
    
    // Appearance
    private let size: CGFloat = 38
    
    private var baseColor: Color {
        IntensityGradientSpec.baseColor(from: baseHex, fallback: .pulseBlue)
    }
    
    var body: some View {
        Button {
            Haptics.lightTap()
            action()
        } label: {
            ZStack {
                // Ring background
                Circle()
                    .fill(.white)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.pulseBlue : Color(UIColor.systemGray5), lineWidth: 4)
                    )
                
                // Gradated fill for first N
                if isFilled {
                    let pair = IntensityGradientSpec.pair(for: number)
                    Circle()
                        .fill(baseColor)
                        .brightness(pair.brightness)
                        .saturation(pair.saturation)
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color(baseColor) : Color(UIColor.clear), lineWidth: 4)
                        )
                        .transition(.opacity)
                }
                
                // Number
                Text("\(number)")
                    .font(.headline)
                    .fontWeight(isSelected ? .bold : .semibold)
                    .foregroundStyle(isFilled ? .white : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Intensity \(number)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview("IntensityButtonView") {
    VStack(spacing: 16) {
        IntensityButtonView(
            number: 1,
            isSelected: false,
            isFilled: false,
            baseHex: nil,
            action: {}
        )
        IntensityButtonView(
            number: 4,
            isSelected: true,
            isFilled: true,
            baseHex: "#8B3A3A",
            action: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
