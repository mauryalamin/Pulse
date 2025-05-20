//
//  CapsuleButton.swift
//  Pulse
//
//  Created by Maury Alamin on 5/20/25.
//

import SwiftUI

struct CapsuleButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    init(_ label: String, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .white : Color.pulseBlue)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.pulseBlue : Color.pulseBlue.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.pulseBlue, lineWidth: 1)
                )
                .padding(.vertical, 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CapsuleButton("Sex", isSelected: false, action: {})
}
