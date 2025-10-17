//
//  OnboardingFlowView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/10/25.
//

import SwiftUI

struct OnboardingFlowView: View {
    var body: some View {
        NavigationStack {
            OnboardingStepOneView(headline: "Welcome to Pulse", subtitle: "Built for quiet control, self-awareness, and total privacy.", image: "Onboarding-1")
        }
    }
}

#Preview {
    OnboardingFlowView()
}
