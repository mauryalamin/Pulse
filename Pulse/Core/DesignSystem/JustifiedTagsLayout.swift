//
//  JustifiedTagsLayout.swift
//  Pulse
//
//  Created by Maury Alamin on 10/26/25.
//

import SwiftUI

/// A simple flow layout that wraps tags into rows with a fixed horizontal gap.
/// Rows are left-aligned (no edge justification).
struct JustifiedTagsLayout: Layout {
    var interitemSpacing: CGFloat = 12
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        guard maxWidth.isFinite, !subviews.isEmpty else { return .zero }

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            let itemWidth = min(size.width, maxWidth)
            let itemHeight = size.height

            // Does it fit in the current row?
            if x > 0 && x + interitemSpacing + itemWidth > maxWidth {
                // move to next row
                y += rowHeight + rowSpacing
                x = 0
                rowHeight = 0
            }

            // place virtually
            if x > 0 { x += interitemSpacing }
            x += itemWidth
            rowHeight = max(rowHeight, itemHeight)
        }

        // Add last row height
        y += rowHeight
        return CGSize(width: maxWidth, height: y)
    }

    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout Void) {
        let maxWidth = bounds.width
        guard maxWidth.isFinite, !subviews.isEmpty else { return }

        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            let width = min(size.width, maxWidth)
            let height = size.height

            // Wrap to next line if needed
            if x > bounds.minX && x + interitemSpacing + width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + rowSpacing
                rowHeight = 0
            }

            view.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: width, height: height)
            )

            x += width + interitemSpacing
            rowHeight = max(rowHeight, height)
        }
    }
}
