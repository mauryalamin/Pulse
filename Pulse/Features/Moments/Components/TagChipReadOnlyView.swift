//
//  TagChipReadOnlyView.swift
//  Pulse
//
//  Created by Maury Alamin on 11/10/25.
//

import SwiftUI

struct TagChipReadOnlyView: View {
    let text: String

    var body: some View {
            Text(text)
            .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(UIColor.systemGray5))
                .clipShape(Capsule())
                .fixedSize(horizontal: true, vertical: false) // keep single-line chip
                .accessibilityLabel("Tag")
                .accessibilityValue(text)
        }
}


#Preview {
    TagChipReadOnlyView(text: "Bored")
}
