//
//  InsightsByTheNumbersSectionView.swift
//  Pulse
//
//  Created by Codex on 3/12/26.
//

import SwiftUI

struct InsightsByTheNumbersSectionView: View {
    let factoids: [InsightFactoid]
    let dataState: InsightsDataState

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var eligibleFactoids: [InsightFactoid] {
        factoids
            .filter(\.isEligible)
            .sorted { lhs, rhs in
                if lhs.priority == rhs.priority {
                    return lhs.kind.rawValue < rhs.kind.rawValue
                }
                return lhs.priority < rhs.priority
            }
    }

    var body: some View {
        InsightsSectionCard(title: "By the Numbers") {
            if eligibleFactoids.isEmpty {
                Text(fallbackCopy)
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(eligibleFactoids) { factoid in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(factoid.valueText)
                                .font(.title3)
                                .fontWeight(.bold)
                                .fontDesign(.rounded)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Text(factoid.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let subtitle = factoid.subtitle, !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(10)
                        .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }

    private var fallbackCopy: String {
        switch dataState {
        case .empty:
            return "No numbers to show yet."
        case .insufficientData:
            return "More moments are needed to unlock detailed metrics."
        case .ready:
            return "No eligible factoids are available."
        case .locked:
            return "By the Numbers is locked."
        }
    }
}
#Preview("Ready") {
    InsightsByTheNumbersSectionView(
        factoids: InsightsPreviewFixtures.factoids,
        dataState: .ready
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Insufficient") {
    InsightsByTheNumbersSectionView(
        factoids: [],
        dataState: .insufficientData
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
