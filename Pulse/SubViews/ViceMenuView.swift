//
//  ViceMenuView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/9/25.
//

import SwiftUI

struct ViceMenuView: View {
    // @Query var vices: [Vice]
    let vices = ViceDefaults.builtIn
    @State private var selectedVice: Vice?

    var body: some View {
        Menu {
            ForEach(vices) { vice in
                Button(action: {
                    selectedVice = vice
                }) {
                    HStack {
                        Circle()
                            .fill(Color(hex: vice.colorHex) ?? .gray)
                            .frame(width: 15, height: 15)
                        Text(vice.name)
                    }
                }
            }
        } label: {
            HStack {
                if let selected = selectedVice {
                    Circle()
                        .fill(Color(hex: selected.colorHex) ?? .gray)
                        .frame(width: 15, height: 15)
                    Text(selected.name)
                        .foregroundStyle(.primary)
                } else {
                    Text("Add")
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundStyle(.gray)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    ViceMenuView()
}
