//
//  MomentDetailView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/12/25.
//

import SwiftUI

struct MomentDetailView: View {
    
    let moment: Moment
    
    @State private var showingEditSheet = false
    
    var body: some View {
        ZStack {
            Color(.grayBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack {
                    VStack (alignment: .leading, spacing: 32) {
                        VStack (alignment: .leading, spacing: 16) {
                            Text("LOGGED DETAILS")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Divider()
                            
                            VStack (alignment: .leading, spacing: 24) {
                                // MARK: - Urge Type
                                VStack (alignment: .leading, spacing: 4) {
                                    Text("What did you feel the urge for?")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                    HStack {
                                        Image(systemName: "circle.fill")
                                            .font(.callout)
                                            .foregroundColor(Color(hex: moment.urge.colorHex) ?? .gray)
                                        Text(moment.urge.name)
                                            .font(.title3)
                                    }
                                }
                                
                                // MARK: - Intensity
                                if let descriptor = IntensityLabel.from(moment.intensity) {
                                    VStack (alignment: .leading, spacing: 4) {
                                        Text("How strong was the urge?")
                                            .font(.headline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                        HStack {
                                            Image(systemName: descriptor.symbolName)
                                                .font(.callout)
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color(hex: moment.urge.colorHex) ?? .gray)
                                            Text(descriptor.label)
                                                .font(.title3)
                                        }
                                        IntensityBarView(intensity: moment.intensity, hexColor: moment.urge.colorHex, includeBug: false)
                                        
                                    }
                                }
                                
                                // MARK: - Response
                                VStack (alignment: .leading, spacing: 4) {
                                    Text("How did you respond?")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                    ResponseTypeTagView(iGaveIn: moment.gaveIn)
                                }
                                .padding(.bottom, 6)
                            }
                            
                            Divider()
                        }
                        
                        // MARK: - Tags & Notes
                        
                        VStack (alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .font(.body)
                                    .foregroundStyle(.blue)
                                Image(systemName: "text.bubble.fill")
                                    .font(.body)
                                    .foregroundStyle(.green)
                                Text("TAGS & NOTES")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                            }
                            
                            // MARK: - Tags
                            TagsReadOnlySectionView(tags: moment.tags ?? [])
                            
                            // MARK: - Notes
                            NotesReadOnlySectionView(note: moment.note)
                            
                            Divider()
                        }
                        
                        // MARK: - Contextual Content
                        VStack (alignment: .leading, spacing: 12) {
                            Text("AROUND THIS MOMENT")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.pulseBlue)
                            
                            // Timestamp
                            Text(moment.timestamp.formatted(date: .abbreviated, time: .shortened))
                            
                            HStack (alignment: .top, spacing: 32) {
                                // MARK: - Weather
                                if moment.temperature != nil || moment.weatherCode != nil {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: WeatherSnapshot(temperature: moment.temperature, conditionCode: moment.weatherCode).sfSymbol)
                                            .font(.body)
                                            .foregroundStyle(.secondary)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(WeatherSnapshotFormatter.formatted(code: moment.weatherCode, temp: moment.temperature))
                                            
                                            
                                        }
                                    }
                                } else {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "cloud.sun.fill")
                                            .font(.body)
                                            .foregroundStyle(.secondary)
                                        
                                        Text("No weather data was captured.")
                                            .font(.body)
                                            .foregroundStyle(.secondary)
                                            .italic()
                                    }
                                }
                                
                                // MARK: - Location
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.body)
                                        .foregroundStyle(.green)
                                    
                                    if let location = moment.locationDescription {
                                        Text(location)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                            .multilineTextAlignment(.leading)
                                    } else {
                                        Text("No location was captured.")
                                            .font(.body)
                                            .foregroundStyle(.secondary)
                                            .italic()
                                    }
                                }
                            }
                            
                            Button {
                                
                            } label: {
                                Text("Show More")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                
                            }
                            
                        }
                        
                        // MARK: - Edit Moment Button
                        HStack {
                            Spacer()
                            Button("Edit This Moment") {
                                showingEditSheet = true
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
            .navigationSubtitle(moment.timestamp.formatted(date: .abbreviated, time: .shortened))
            .sheet(isPresented: $showingEditSheet) {
                UpdateMomentView(moment: moment)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                }
            }
        }
    }
    
}

#Preview {
    NavigationStack {
        MomentDetailView(moment: Moment(timestamp: .now, urge: Urge(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 5, gaveIn: false))
    }
}
