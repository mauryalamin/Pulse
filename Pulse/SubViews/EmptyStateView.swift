//
//  EmptyStateView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/8/25.
//

import SwiftUI

struct EmptyStateView: View {
    
    var logMoment: (() -> Void)?
    
    var body: some View {
        VStack (alignment: .center, spacing: 24){
            VStack {
                Text("Every journey begins with noticing")
                    .multilineTextAlignment(.center)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .foregroundStyle(.pulseBlue)
                Text("Pulse is ready whenever you are.")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Image(.emptyState)
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 200)
            Button {
                self.logMoment?()
            } label: {
                EmptyStateLogButtonView()
            }
            .buttonStyle(PlainButtonStyle())
            // Isolates the shadow to this view
            .compositingGroup()
            .shadow(radius: 12)
            
            
                
        }
    }
}

#Preview {
    EmptyStateView()
}
