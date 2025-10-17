//
//  TagView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/15/25.
//

import SwiftUI

struct TagView: View {
    
    var tag: String
    
    var body: some View {
        Text(tag)
            .font(.footnote)
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Color.pulseBlue.opacity(0.2))
            .cornerRadius(6)
            .frame(maxWidth: 180, alignment: .leading)
            .lineLimit(1)
            .truncationMode(.tail)
        
    }
}

#Preview {
    TagView(tag: "Nervous")
}
