//
//  MomentFilterSheetView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/19/25.
//

import SwiftUI
import SwiftData

struct MomentFilterSheetView: View {
    @Binding var selectedUrge: Urge?
    @Binding var selectedTag: Tag?
    @Binding var selectedIntensity: Int?
    @Binding var stayedPresentOnly: Bool
    @Binding var followedOnly: Bool

    @Environment(\.dismiss) private var dismiss

    @Query private var urges: [Urge]
    @Query private var tags: [Tag]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Urge Type")) {
                    ScrollView(.horizontal) {
                        HStack {
                            Button("All") {
                                selectedUrge = nil
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(selectedUrge == nil ? .blue : .gray)

                            ForEach(urges) { urge in
                                Button(urge.name) {
                                    selectedUrge = urge
                                }
                                .buttonStyle(.bordered)
                                .tint(selectedUrge?.id == urge.id ? .blue : .gray)
                            }
                        }
                    }
                }

                Section(header: Text("Tag")) {
                    ScrollView(.horizontal) {
                        HStack {
                            Button("All") {
                                selectedTag = nil
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(selectedTag == nil ? .blue : .gray)

                            ForEach(tags) { tag in
                                Button(tag.name) {
                                    selectedTag = tag
                                }
                                .buttonStyle(.bordered)
                                .tint(selectedTag?.id == tag.id ? .blue : .gray)
                            }
                        }
                    }
                }

                Section(header: Text("Intensity")) {
                    HStack {
                        Button("All") {
                            selectedIntensity = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(selectedIntensity == nil ? .blue : .gray)

                        ForEach(1...5, id: \.self) { level in
                            Button("\(level)") {
                                selectedIntensity = level
                            }
                            .buttonStyle(.bordered)
                            .tint(selectedIntensity == level ? .blue : .gray)
                        }
                    }
                }

                Section(header: Text("State")) {
                    Toggle("Stayed Present Only", isOn: $stayedPresentOnly)
                    Toggle("Urge Followed Only", isOn: $followedOnly)
                }

                Section {
                    Button("Clear All Filters") {
                        selectedUrge = nil
                        selectedTag = nil
                        selectedIntensity = nil
                        stayedPresentOnly = false
                        followedOnly = false
                    }
                    .foregroundColor(.red)
                }
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

#Preview {
    MomentFilterSheetView(selectedUrge: .constant(Urge(name: "Test Urge", colorHex: "#FF0000")), selectedTag: .constant(Tag(name: "Hunger")), selectedIntensity: .constant(1), stayedPresentOnly: .constant(false), followedOnly: .constant(false))
}
