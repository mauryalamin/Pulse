//
//  MomentDetailView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/12/25.
//

import SwiftUI

struct MomentDetailView: View {
    
    let moment: Moment
    
    var body: some View {
        ZStack {
            Color(.grayBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack {
                    VStack (alignment: .leading, spacing: 32) {
                        VStack (alignment: .leading, spacing: 12) {
                            Text("LOGGED DETAILS")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.pulseBlue)
                            Divider()
                            
                            // Urge Type
                            HStack (spacing: 12) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 42))
                                    .foregroundColor(Color(hex: moment.urge.colorHex) ?? .gray)
                                VStack (alignment: .leading) {
                                    Text("What did you feel the urge for?")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                    Text(moment.urge.name)
                                        .fontWeight(.light)
                                }
                            }
                            Divider()
                            
                            // Intensity
                            if let descriptor = IntensityLabel.from(moment.intensity) {
                                HStack(spacing: 12) {
                                    Image(systemName: descriptor.symbolName)
                                        .font(.system(size: 42))
                                        .foregroundColor(Color(hex: moment.urge.colorHex) ?? .gray)
                                    VStack (alignment: .leading) {
                                        Text("How strong was the urge?")
                                            .font(.title3)
                                            .fontWeight(.medium)
                                        Text(descriptor.label)
                                            .font(.body)
                                            .fontWeight(.light)
                                    }
                                }
                            }
                            Divider()
                            
                            // Response
                            HStack (spacing: 12) {
                                Image(systemName: moment.gaveIn ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                                    .font(.system(size: 42))
                                    .foregroundStyle(moment.gaveIn ? .gaveIn : .sageGreen)
                                VStack (alignment: .leading) {
                                    Text("How did you respond?")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                    Text(moment.gaveIn ? "I gave in" : "Stayed Present")
                                        .fontWeight(.light)
                                }
                            }
                            Divider()
                        }
                        
                        VStack (alignment: .leading, spacing: 24) {
                            Text("TAGS & NOTES")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.pulseBlue)
                            
                            // Tags (will need to be converted to a grid)
                            HStack (spacing: 12) {
                                Text("Nervous")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                    .background(Color.pulseBlue.opacity(0.2))
                                    .cornerRadius(4)
                                Text("Hungry")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                    .background(Color.pulseBlue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            
                            // Notes
                            if let note = moment.note {
                                Text(note)
                            } else {
                                Text("No notes")
                                    .foregroundStyle(.secondary)
                            }
                            
                            Divider()
                        }
                        
                        VStack (alignment: .leading, spacing: 12) {
                            Text("AROUND THIS MOMENT")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.pulseBlue)
                            
                            // Timestamp
                            Text(moment.timestamp.formatted(date: .abbreviated, time: .shortened))
                            
                            HStack (spacing: 24) {
                                HStack {
                                    Image(systemName: "cloud.drizzle.fill")
                                        .font(.body)
                                        .foregroundStyle(.gray)
                                    Text("65°F")
                                }
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.body)
                                        .foregroundStyle(.green)
                                    Text("Near Vernon Hills")
                                }
                            }
                            
                            Button {
                                
                            } label: {
                                Text("Show More")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                
                            }
                            
                        }
                        
                        HStack {
                            Spacer()
                            Button("Edit This Moment") {
                                
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    
                }
                .padding(.bottom, 200)
                .background(.white)
                .cornerRadius(20)
            }
            
            .navigationTitle("Logged Moment")
        }
    }
    
}

#Preview {
    NavigationStack {
        MomentDetailView(moment: Moment(urge: Urge(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 5, gaveIn: false))
    }
}
