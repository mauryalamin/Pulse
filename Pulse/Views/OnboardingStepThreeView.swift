//
//  OnboardingStepThreeView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/10/25.
//

import SwiftUI

struct OnboardingStepThreeView: View {
    @AppStorage("isOnboarding") var isOnboarding: Bool = true
    
    var headline: String
    var subtitle: String
    var image: String
    
    var body: some View {
        ZStack {
            Color(.grayBackground)
                .ignoresSafeArea()
            ScrollView {
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Everything stays on your phone—no accounts, no syncing, no tracking. You can protect Pulse with Face ID and hide its purpose with Stealth Mode.")
                        VStack(alignment: .leading, spacing: 8) {
                            HStack (alignment: .top){
                                Text("•")
                                    .frame(width: 20)
                                Text("No accounts or logins")
                            }
                            HStack (alignment: .top){
                                Text("•")
                                    .frame(width: 20)
                                Text("Optional Face ID / passcode lock")
                            }
                            HStack (alignment: .top){
                                Text("•")
                                    .frame(width: 20)
                                Text("Stealth Mode hides app appearance & behavior")
                            }
                        }
                    }
                    .multilineTextAlignment(.leading)
                    .font(.callout)
                    .fontWeight(.light)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // MARK: - Privacy Options
                    VStack (alignment: .center) {
                        HStack {
                            Spacer()
                            VStack (spacing: 24) {
                                Button("Enable Face ID") {
                                    
                                }
                                
                                NavigationLink(destination: OnboardingStepFourView(headline: "Stealth Mode helps Pulse blend in", subtitle: "Pick a name and icon to help Pulse appear neutral on your phone. You can always change this later.", image: "Onboarding-4")) {
                                    Text("Enable Stealth Mode")
                                }
                            }
                            Spacer()
                        }
                        .padding(.bottom)
                        Text("You can change these settings anytime in the app")
                            .font(.caption)
                    }
                    
                    // MARK: - Next Button
                    Button {
                        isOnboarding = false
                    } label: {
                        Text("Start Using Pulse")
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
            }
            .scrollIndicators(.hidden)
            .offset(y: 20)
            .padding(.horizontal)
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingStepThreeView(headline: "Your privacy comes first", subtitle: "Everything stays on your phone…", image: "Onboarding-3")
    }
}
