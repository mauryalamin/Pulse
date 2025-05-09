//
//  ViceListView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/8/25.
//

import SwiftUI

struct ViceListView: View {
    
    let defaultVices = ViceDefaults.builtIn
    var selectedVice: Vice?
    
    var body: some View {
        List {
            ForEach(defaultVices) { vice in
                HStack (alignment: .center){
                    Image(systemName: "circle.fill")
                        .foregroundStyle(Color(hex: vice.colorHex) ?? .gray)
                    Text(vice.name)
                }
            }
            Button(action: {
                
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add New Craving")
                }
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Select a Craving")
    }
}

#Preview {
    ViceListView()
}
