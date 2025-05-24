//
//  OnboardingStepTwoView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/10/25.
//

import SwiftUI

struct OnboardingStepTwoView: View {
    
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
                    
                    // MARK: - Hero image
                    Image(image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 220, height: 220)
                    
                    // MARK: - Body Content
                    VStack(alignment: .leading, spacing: 8) {
                        HStack (alignment: .top){
                            Text("•")
                                .frame(width: 20)
                            Text("Log in seconds using widgets or Quick Actions")
                        }
                        HStack (alignment: .top){
                            Text("•")
                                .frame(width: 20)
                            Text("Add optional context when you're ready")
                        }
                        HStack (alignment: .top){
                            Text("•")
                                .frame(width: 20)
                            Text("Pulse can auto-capture time, calendar, and more (with permission)")
                        }
                    }
                    .multilineTextAlignment(.leading)
                    .font(.callout)
                    .fontWeight(.light)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
                
                // MARK: - Next Button
                NavigationLink(destination: OnboardingStepThreeView(headline: "Your privacy comes first", subtitle: "Everything stays on your phone…", image: "Onboarding-3")) {
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
                NavigationLink(destination: OnboardingStepThreeView(headline: "Your privacy comes first", subtitle: "Everything stays on your phone…", image: "Onboarding-3")) {
                    Text("Next")
                }
            }
        }
    }
    
}

#Preview {
    NavigationStack {
        OnboardingStepTwoView(headline: "Quietly track cravings, urges, and thoughts", subtitle: "Here’s what Pulse helps you do:", image: "Onboarding-2")
    }
}
