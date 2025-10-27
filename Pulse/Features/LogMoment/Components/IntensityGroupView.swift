//
//  IntensityGroupView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/9/25.
//

import SwiftUI

struct IntensityGroupView: View {
    @Binding var selectedIntensity: Int?
    var baseHex: String? = nil   // NEW: pass urge.colorHex (or nil → Pulse Blue)

    var body: some View {
        HStack(spacing: 14) {
            ForEach(1...5, id: \.self) { number in
                IntensityButtonView(
                    number: number,
                    isSelected: selectedIntensity == number,
                    isFilled: (selectedIntensity ?? 0) >= number,
                    baseHex: baseHex,
                    action: { selectedIntensity = number }
                )
            }
        }
        .animation(.easeInOut(duration: 0.15), value: selectedIntensity)
    }
}

#Preview("IntensityGroupView") {
    struct Demo: View {
        @State private var value: Int? = 3
        @State private var useUrge = true
        var body: some View {
            VStack(spacing: 24) {
                IntensityGroupView(
                    selectedIntensity: $value,
                    baseHex: useUrge ? "#8B3A3A" : nil
                )
                Toggle("Use Urge Color", isOn: $useUrge)
                Text("Selected: \(value.map(String.init) ?? "none")")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
        }
    }
    return Demo()
}
