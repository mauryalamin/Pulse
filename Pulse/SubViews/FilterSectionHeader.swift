//
//  FilterSectionHeader.swift
//  Pulse
//
//  Created by Maury Alamin on 5/20/25.
//

import SwiftUI

struct FilterSectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.horizontal)
    }
}

#Preview {
    FilterSectionHeader("Urge")
}
