//
//  TagsReadOnlySectionView.swift
//  Pulse
//
//  Created by Maury Alamin on 11/10/25.
//

import SwiftUI
import SwiftData

// Disambiguate the app's Tag model for use in this file
typealias AppTag = Tag

// MARK: - Tiny helper intentionally made internal so tests can @testable import and assert it
enum TagsA11y {
    static func summary(for tags: [AppTag]) -> String {
        guard !tags.isEmpty else { return "No tags added" }
        return tags.map { $0.name }.joined(separator: ", ")
    }
}

struct TagsReadOnlySectionView: View {
    let tags: [AppTag]
    var interitemSpacing: CGFloat = 12
    var rowSpacing: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header lives in your Detail view (per your note), so body only shows the collection
            if tags.isEmpty {
                Text("No tags added")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                JustifiedTagsLayout(
                    interitemSpacing: interitemSpacing,
                    rowSpacing: rowSpacing
                ) {
                    ForEach(tags) { tag in
                        TagChipReadOnlyView(text: tag.name)
                    }
                }
            }
        }
        // Make the whole block readable as a single element, with a value we can test
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tags")
        .accessibilityValue(TagsA11y.summary(for: tags))
    }
}

#Preview("Detail • With Tags") {
    let container = try! ModelContainer(
        for: Moment.self, Urge.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = ModelContext(container)

    let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
    let t1 = Tag(name: "After Work")
    let t2 = Tag(name: "Stress")
    ctx.insert(urge); ctx.insert(t1); ctx.insert(t2)

    let m = Moment(timestamp: .now, urge: urge, intensity: 3, gaveIn: false, note: "Sample", tags: [t1, t2])

    return NavigationStack {
        List {
            TagsReadOnlySectionView(tags: m.tags ?? [])
        }
        .navigationTitle("Moment")
    }
    .modelContainer(container)
}

#Preview("Detail • No Tags") {
    let container = try! ModelContainer(
        for: Moment.self, Urge.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = ModelContext(container)

    let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
    ctx.insert(urge)
    let m = Moment(timestamp: .now, urge: urge, intensity: 2, gaveIn: true, note: nil, tags: [])

    return NavigationStack {
        List {
            TagsReadOnlySectionView(tags: m.tags ?? [])
        }
        .navigationTitle("Moment")
    }
    .modelContainer(container)
}
