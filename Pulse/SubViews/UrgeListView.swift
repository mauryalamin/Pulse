//
//  UrgeListView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/8/25.
//

import SwiftUI

struct UrgeListView: View {
    
    let defaultUrges = UrgeDefaults.builtIn
    var selectedUrge: Urge?
    
    var body: some View {
        List {
            ForEach(defaultUrges) { urge in
                HStack (alignment: .center){
                    Image(systemName: "circle.fill")
                        .foregroundStyle(Color(hex: urge.colorHex) ?? .gray)
                    Text(urge.name)
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
    UrgeListView()
}
