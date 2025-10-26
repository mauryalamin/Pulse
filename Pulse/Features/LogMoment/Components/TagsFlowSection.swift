//
//  TagsFlowSection.swift
//  Pulse
//
//  Created by Maury Alamin on 10/26/25.
//

import SwiftUI

struct TagsFlowSection: View {
    @Binding var selectedTags: [Tag]
    @Binding var showTagPicker: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag.fill")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                Text("Tags")
                    .font(.subheadline).fontWeight(.semibold)
            }

            // Tip: start with AnyLayout to calm the type-checker
            AnyLayout(JustifiedTagsLayout(interitemSpacing: 12, rowSpacing: 8)) {
                ForEach(selectedTags, id: \.id) { tag in
                    TagView(tag: tag.name)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Button(action: { showTagPicker = true }) {
                    Label("Add", systemImage: "plus")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.pulseBlue.opacity(0.2))
                        .foregroundColor(.blue)
                        .font(.subheadline)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    TagsFlowSection(selectedTags: .constant([]), showTagPicker: .constant(true))
}
