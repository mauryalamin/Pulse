//
//  MomentFilterSheetView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/19/25.
//

import SwiftUI
import SwiftData

struct MomentFilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedUrge: Urge?
    @Binding var selectedTag: Tag?
    @Binding var selectedIntensity: Int?
    @Binding var stayedPresentOnly: Bool
    @Binding var followedOnly: Bool

    @Query private var urges: [Urge]
    @Query private var tags: [Tag]

    var body: some View {
        NavigationStack {
        ZStack {
            Color(.grayBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {

                    // MARK: - Urge
                    VStack (alignment: .leading){
                        FilterSectionHeader("Urge")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                CapsuleButton("All", isSelected: selectedUrge == nil) {
                                    selectedUrge = nil
                                }
                                ForEach(urges) { urge in
                                    CapsuleButton(urge.name, isSelected: selectedUrge?.id == urge.id) {
                                        selectedUrge = urge
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // MARK: - Tag
                    VStack (alignment: .leading) {
                        FilterSectionHeader("Tag")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                CapsuleButton("All", isSelected: selectedTag == nil) {
                                    selectedTag = nil
                                }
                                ForEach(tags) { tag in
                                    CapsuleButton(tag.name, isSelected: selectedTag?.id == tag.id) {
                                        selectedTag = tag
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // MARK: - Intensity
                    VStack (alignment: .leading) {
                        FilterSectionHeader("Intensity")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                CapsuleButton("All", isSelected: selectedIntensity == nil) {
                                    selectedIntensity = nil
                                }
                                ForEach(1...5, id: \.self) { level in
                                    CapsuleButton("\(level)", isSelected: selectedIntensity == level) {
                                        selectedIntensity = level
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider()

                    // MARK: - Response
                    VStack (alignment: .leading) {
                        FilterSectionHeader("Response")
                        VStack(spacing: 8) {
                            Toggle("Stayed Present Only", isOn: $stayedPresentOnly)
                            Toggle("Urge Followed Only", isOn: $followedOnly)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()

                    // MARK: - Clear Button
                    Button("Clear All Filters") {
                        selectedUrge = nil
                        selectedTag = nil
                        selectedIntensity = nil
                        stayedPresentOnly = false
                        followedOnly = false
                    }
                    .foregroundColor(.red)
                    .padding(.top, 8)
                    .padding(.horizontal)

                }
                .padding(.top)
            }
            .navigationTitle("Filter Moments")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        }
    }
}

#Preview {
    MomentFilterSheetView(selectedUrge: .constant(Urge(name: "Test Urge", colorHex: "#FF0000")), selectedTag: .constant(Tag(name: "Hunger")), selectedIntensity: .constant(1), stayedPresentOnly: .constant(false), followedOnly: .constant(false))
}
