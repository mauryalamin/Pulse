//
//  InsightsSectionCard.swift
//  Pulse
//
//  Created by Codex on 3/12/26.
//

import SwiftUI

struct InsightsSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
