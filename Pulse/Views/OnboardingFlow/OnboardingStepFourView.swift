//
//  OnboardingStepFourView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/14/25.
//

import SwiftUI

struct OnboardingStepFourView: View {
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
                    VStack (spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack (alignment: .top){
                                Text("•")
                                    .frame(width: 20)
                                Text("Stealth Mode helps Pulse blend in by letting you choose a more neutral app icon.")
                            }
                            HStack (alignment: .top){
                                Text("•")
                                    .frame(width: 20)
                                Text("Inside, your Moments stay secure — protected by Face ID and never surfaced through notifications.")
                            }
                        }
                        .multilineTextAlignment(.leading)
                        .font(.callout)
                        .fontWeight(.light)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("You can still log moments instantly — but only you will know.")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.pulseBlue)
                    }
                    
                    Divider()
                    
                    // MARK: -  Custom Icon
                    
                    VStack (alignment: .leading, spacing: 8) {
                        Text("Stealth App Icon")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        HStack  {
                            VStack (alignment: .center, spacing: 8) {
                                Image(.iconA)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 68, height: 68)
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .fontWeight(.light)
                            }
                            Spacer()
                            VStack (alignment: .center, spacing: 8) {
                                Image(.iconB)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 68, height: 68)
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .fontWeight(.light)
                            }
                            Spacer()
                            VStack (alignment: .center, spacing: 8) {
                                Image(.iconC)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 68, height: 68)
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .fontWeight(.light)
                            }
                            Spacer()
                            VStack (alignment: .center, spacing: 8) {
                                Image(.iconD)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 68, height: 68)
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .fontWeight(.light)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    // MARK: - Preview
                    VStack (alignment: .center, spacing: 10) {
                        Text("How It Will Look")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Image(.preview)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 292, height: 101)
                    }
                    
                    // MARK: - Save Configuration
                    VStack (alignment: .center, spacing: 8) {
                        Button("Save Changes") {
                            
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom)
                        
                        Button("Cancel") {
                            
                        }
                        .padding(.bottom)
                        
                        Text("You can change these settings anytime in the app")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.bottom)
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
            .padding(.bottom)
        }
    }
}

#Preview {
    OnboardingStepFourView(headline: "Make Pulse less visible", subtitle: "Choose an icon that feels more private to you.", image: "Onboarding-4")
}
