//
//  IntensityGroupView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/9/25.
//

import SwiftUI

struct IntensityGroupView: View {
    @Binding var selectedIntensity: Int?
    
    var body: some View {
        HStack (spacing: 20) {
            ForEach(1...5, id: \.self) { number in
                IntensityButtonView(
                    number: number,
                    isSelected: selectedIntensity == number,
                    action: {
                        selectedIntensity = number
                    })
            }
        }
    }
}

#Preview {
    IntensityGroupView(selectedIntensity: .constant(1))
}
