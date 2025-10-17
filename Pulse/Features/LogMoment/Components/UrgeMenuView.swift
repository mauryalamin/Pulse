//
//  UrgeMenuView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/9/25.
//

import SwiftUI
import SwiftData

struct UrgeMenuView: View {
    @Binding var selectedUrge: Urge?
    @Query private var urges: [Urge] // Automatically fetches all urges from SwiftData
    @State private var showingNewUrgeSheet = false
    
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
            Divider()
            Button {
                showingNewUrgeSheet = true
            } label: {
                Label("Add New…", systemImage: "plus")
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
        .sheet(isPresented: $showingNewUrgeSheet) {
            NewUrgeView { newUrge in
                selectedUrge = newUrge
            }
        }
    }
}

#Preview {
    UrgeMenuView(selectedUrge: .constant(Urge(name: "Test Urge", colorHex: "#FF0000")))
}
