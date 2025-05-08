//
//  FactoidGroupView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/8/25.
//

import SwiftUI

struct FactoidGroupView: View {
    var body: some View {
        HStack (spacing:14) {
            FactoidView(icon: "list.bullet", numbers: 24, typeLabel: "Moments Captured")
            FactoidView(icon: "checkmark.seal", numbers: 18, typeLabel: "Stayed Present")
            FactoidView(icon: "exclamationmark.2", numbers: 3, typeLabel: "Average Intensity")
        }
    }
}

#Preview {
    FactoidGroupView()
}
