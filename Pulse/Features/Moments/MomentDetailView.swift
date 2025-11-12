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
                                .foregroundStyle(.primary)
                            
                            // Timestamp
                            Text(moment.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                                        
                             HStack (spacing: 36) {
                                HStack(spacing: 6) {
                                    Image(systemName: moment.weatherIcon)   // ← renders ☁️ (etc.), not the text "cloud.fill"
                                    Text(temperatureString(fromCelsius: moment.temperature))
                                }
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                
                                // Location (saved snapshot)
                                if let place = moment.locationDescription {
                                    HStack(spacing: 6) {
                                        Image(systemName: "mappin.circle.fill")
                                        Text(place)
                                    }
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
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
                .background(.cardBackground)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 25, x: 0, y: -3)
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
    
    private func temperatureString(fromCelsius celsius: Double?) -> String {
        guard let celsius else { return "—" }

        // Modern locale check (replaces deprecated usesMetricSystem)
        let usesFahrenheit = Locale.current.measurementSystem == .us

        // Convert and round
        let value: Double = usesFahrenheit ? (celsius * 9.0/5.0 + 32.0) : celsius
        let rounded = Int((value).rounded())

        // Force the unit suffix so it never disappears
        let unit = usesFahrenheit ? "F" : "C"
        return "\(rounded)°\(unit)"
    }
    
}

#Preview {
    NavigationStack {
        MomentDetailView(
            moment: Moment(
                timestamp: .now.addingTimeInterval(-3600), // 1 hour ago
                urge: Urge(name: "Alcohol", colorHex: "#8B3A3A"),
                intensity: 5,
                gaveIn: false,
                note: "Felt the urge after a long day, but stayed present.",
                tags: [
                    Tag(name: "After Work"),
                    Tag(name: "Stress Relief")
                ],
                locationDescription: "Chicago, IL",
                latitude: 41.8781,
                longitude: -87.6298,
                temperature: 13.6,
                weatherCode: 3 // cloud.fill in SF Symbols mapping
            )
        )
    }
}
