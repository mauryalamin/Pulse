//
//  EmptyStateLogButtonView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/8/25.
//

import SwiftUI

struct EmptyStateLogButtonView: View {
    var body: some View {
        HStack (spacing: 8) {
            LogMomentButton(size: 42)
                //.padding()
            Text("Log a Moment")
                .font(.callout)
                .fontDesign(.rounded)
        }
        .padding(10)
        .background(
            Color(.white),
            in: Capsule()
        )
    }
}

#Preview {
    EmptyStateLogButtonView()
}
