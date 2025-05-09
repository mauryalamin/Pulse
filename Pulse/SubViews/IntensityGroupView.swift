//
//  IntensityGroupView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/9/25.
//

import SwiftUI

struct IntensityGroupView: View {
    var body: some View {
        HStack (spacing: 20) {
            IntensityButtonView(intensity: 1)
            IntensityButtonView(intensity: 2)
            IntensityButtonView(intensity: 3)
            IntensityButtonView(intensity: 4)
            IntensityButtonView(intensity: 5)
        }
    }
}

#Preview {
    IntensityGroupView()
}
