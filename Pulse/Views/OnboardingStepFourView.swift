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
                    // Header Content
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
                    Image(image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 220, height: 220)
                    
                    // Bullet List
                    VStack (spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack (alignment: .top){
                                Text("•")
                                    .frame(width: 20)
                                Text("Hides the Pulse app name and icon")
                            }
                            HStack (alignment: .top){
                                Text("•")
                                    .frame(width: 20)
                                Text("Uses neutral labels on widgets and Quick Actions")
                            }
                            HStack (alignment: .top){
                                Text("•")
                                    .frame(width: 20)
                                Text("Hides log entries behind Face ID")
                            }
                            HStack (alignment: .top){
                                Text("•")
                                    .frame(width: 20)
                                Text("Turns off all notifications")
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
                    
                    // Custom Name and Icon
                    VStack (alignment: .leading, spacing: 8) {
                        Text("Stealth App Name")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        HStack (spacing: 32) {
                            VStack (alignment: .leading, spacing: 12) {
                                HStack (alignment: .center) {
                                    Image(systemName: "circle")
                                        .font(.title3)
                                        .fontWeight(.light)
                                    Text("Focus Log")
                                }
                                HStack (alignment: .center) {
                                    Image(systemName: "circle")
                                        .font(.title3)
                                        .fontWeight(.light)
                                    Text("Moment Journal")
                                }
                            }
                            VStack (alignment: .leading, spacing: 12) {
                                HStack (alignment: .center) {
                                    Image(systemName: "circle")
                                        .font(.title3)
                                        .fontWeight(.light)
                                    Text("Notes+")
                                }
                                HStack (alignment: .center) {
                                    Image(systemName: "circle")
                                        .font(.title3)
                                        .fontWeight(.light)
                                    Text("Archive")
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
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
                    
                    VStack (alignment: .center, spacing: 10) {
                        Text("How It Will Look")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Image(.preview)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 292, height: 101)
                    }
                    
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
    OnboardingStepFourView(headline: "Stealth Mode helps Pulse blend in", subtitle: "Pick a name and icon to help Pulse appear neutral on your phone. You can always change this later.", image: "Onboarding-4")
}
