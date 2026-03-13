//
//  InsightsObservationsSectionView.swift
//  Pulse
//
//  Created by Codex on 3/12/26.
//

import SwiftUI

struct InsightsObservationsSectionView: View {
    let observations: [InsightObservation]
    let dataState: InsightsDataState

    private var topObservations: [InsightObservation] {
        observations
            .sorted { lhs, rhs in
                if lhs.priority == rhs.priority {
                    return lhs.generatedAt > rhs.generatedAt
                }
                return lhs.priority < rhs.priority
            }
            .prefix(2)
            .map { $0 }
    }

    var body: some View {
        InsightsSectionCard(title: "What Stood Out") {
            if topObservations.isEmpty {
                Text(fallbackCopy)
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(topObservations) { observation in
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: "lightbulb.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(Color.pulseBlue.opacity(0.85))
                                .clipShape(Circle())

                            Text(observation.body)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .background(Color(UIColor.systemGray5), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
    }

    private var fallbackCopy: String {
        switch dataState {
        case .empty:
            return "Observations will appear as patterns develop."
        case .insufficientData:
            return "Not enough data yet for standout observations."
        case .ready:
            return "No observations are available right now."
        case .locked:
            return "Observations are locked."
        }
    }
}

#Preview("Ready") {
    InsightsObservationsSectionView(
        observations: InsightsPreviewFixtures.observations,
        dataState: .ready
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty") {
    InsightsObservationsSectionView(
        observations: [],
        dataState: .empty
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
