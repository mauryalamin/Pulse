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
            LogMomentButton(size: 42, fontSize: 17)
                //.padding()
            Text("Log a Moment")
                .font(.callout)
                .foregroundStyle(.primary)
                .fontDesign(.rounded)
        }
        .padding(10)
        .glassEffect(.clear.interactive())
    }
}

#Preview {
    EmptyStateLogButtonView()
}
