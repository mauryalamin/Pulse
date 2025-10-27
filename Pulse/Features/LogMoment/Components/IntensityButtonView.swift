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
    let isFilled: Bool           // NEW: first N get filled, not just the selected one
    let baseHex: String?         // NEW: urge color, or nil → Pulse Blue
    let action: () -> Void

    // Spec
    private let brightness: [Double]  = [0.4, 0.3, 0.2, 0.1, 0.0]
    private let saturation: [Double]  = [0.6, 0.7, 0.8, 0.9, 1.0]

    // Colors
    private var baseColor: Color {
        if let hex = baseHex, let c = Color(hex: hex) { return c }
        return .pulseBlue
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            ZStack {
                // Background ring (when not filled)
                Circle()
                    .fill(.white)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.pulseBlue : Color(UIColor.systemGray5), lineWidth: 4)
                    )

                // Gradated fill for first N buttons
                if isFilled {
                    Circle()
                        .fill(baseColor)
                        .brightness(brightness[max(0, number - 1)])
                        .saturation(saturation[max(0, number - 1)])
                        .frame(width: 38, height: 38)
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
        // Not filled
        IntensityButtonView(
            number: 1,
            isSelected: false,
            isFilled: false,
            baseHex: nil,
            action: {}
        )
        // Filled + selected
        IntensityButtonView(
            number: 3,
            isSelected: true,
            isFilled: true,
            baseHex: "#8B3A3A",
            action: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
