//
//  OnboardingStepOneView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/10/25.
//

import SwiftUI

struct OnboardingStepOneView: View {
    
    var headline: String
    var subtitle: String
    var image: String
    
    var body: some View {
        ZStack {
            Color(.grayBackground)
                .ignoresSafeArea()
                VStack {
                    VStack (spacing: 32) {
                        // MARK: - Header Content
                        VStack (spacing: 12) {
                            Text(headline)
                                .multilineTextAlignment(.center)
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                                .fontDesign(.rounded)
                                .foregroundStyle(.pulseBlue)
                            Text(subtitle)
                                .multilineTextAlignment(.center)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 366)
                        }
                        
                        // MARK: - Hero Image
                        Image(image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 220, height: 220)
                        
                        // MARK: - Body Content
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Your moments matter.")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Pulse is a private, fast way to track urges or cravings—without judgment, pressure, or noise.")
                                .font(.title3)
                                .fontWeight(.light)
                                .multilineTextAlignment(.leading)
                                .frame(width: 340)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }
                    Spacer()
                    
                    // MARK: - Next Button
                    NavigationLink(destination: OnboardingStepTwoView(headline: "Quietly track cravings, urges, and thoughts", subtitle: "Here’s what Pulse helps you do:", image: "Onboarding-2")) {
                        Text("Next")
                            .foregroundStyle(.white)
                            .padding(.horizontal,36)
                            .padding(.vertical,20)
                            .background(
                                    Color.accentColor,
                                    in: Capsule()
                                )
                            .compositingGroup()
                            .shadow(radius: 12)
                    }
                }
                .padding()
           // }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: OnboardingStepTwoView(headline: "Quietly track cravings, urges, and thoughts", subtitle: "Here’s what Pulse helps you do:", image: "Onboarding-2")) {
                    Text("Next")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingStepOneView(headline: "Welcome to Pulse", subtitle: "Built for quiet control, self-awareness, and total privacy.", image: "Onboarding-1")
    }
}
