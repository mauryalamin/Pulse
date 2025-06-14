//
//  OnboardingStepFourView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/14/25.
//

import SwiftUI

struct OnboardingStepFourView: View {
    @AppStorage("isOnboarding") var isOnboarding: Bool = true
    
    @AppStorage("isStealthModeEnabled") var isStealthModeEnabled = false
    @AppStorage("selectedStealthIcon") var selectedStealthIcon: String?
    @AppStorage("selectedStealthIcon") private var persistedIcon: String?
    @State private var selectedIcon: String?
    
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
                    
                    // MARK: -  Custom Icon & Preview
                    VStack (alignment: .center, spacing: 8) {
                        Divider()
                        
                        HStack {
                            Spacer()
                            VStack(spacing: 16) {
                                StealthIconPickerView()
                                    .frame(width: 300)
                            }
                            Spacer()
                        }
                       Text("You can change these settings anytime in the app")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.bottom)
                        
                        Divider()
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
