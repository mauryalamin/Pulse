//
//  FlowLayout.swift
//  Pulse
//
//  Created by Maury Alamin on 5/15/25.
//

import SwiftUI

struct FlowLayout<Data: Hashable, Content: View>: View {
    let items: [Data]
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data) -> Content

    init(_ items: [Data],
         spacing: CGFloat = 8,
         alignment: HorizontalAlignment = .leading,
         @ViewBuilder content: @escaping (Data) -> Content) {
        self.items = items
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var rows: [[Data]] = [[]]

        for item in items {
            // Estimate average width per tag
            let estimatedTagWidth: CGFloat = 100

            if width + estimatedTagWidth > geometry.size.width {
                rows.append([item])
                width = estimatedTagWidth + spacing
            } else {
                rows[rows.count - 1].append(item)
                width += estimatedTagWidth + spacing
            }
        }

        return VStack(alignment: alignment, spacing: spacing) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                }
            }
        }
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

#Preview("Tag Grid Flow") {
    FlowLayout([
        "After Work", "Stress", "Scrolling", "Late Night", "Social Setting", "Celebration", "Alone"
    ]) { tag in
        TagView(tag: tag)
    }
    .padding()
}
