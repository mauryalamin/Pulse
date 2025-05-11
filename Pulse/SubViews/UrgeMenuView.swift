//
//  UrgeMenuView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/9/25.
//

import SwiftUI

struct UrgeMenuView: View {
    // @Query var urges: [Urge]
    let urges = UrgeDefaults.builtIn
    @Binding var selectedUrge: Urge?
    // @State private var selectedUrge: Urge?

    var body: some View {
        Menu {
            ForEach(urges) { urge in
                Button(action: {
                    selectedUrge = urge
                }) {
                    HStack {
                        Circle()
                            .fill(Color(hex: urge.colorHex) ?? .gray)
                            .frame(width: 15, height: 15)
                        Text(urge.name)
                    }
                }
            }
        } label: {
            HStack {
                if let selected = selectedUrge {
                    Circle()
                        .fill(Color(hex: selected.colorHex) ?? .gray)
                        .frame(width: 15, height: 15)
                    Text(selected.name)
                        .foregroundStyle(.primary)
                } else {
                    Text("Add")
                        .foregroundStyle(.accent)
                }

                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundStyle(.accent)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    UrgeMenuView(selectedUrge: .constant(Urge(name: "Alcohol", colorHex: "#8B3A3A")))
}
