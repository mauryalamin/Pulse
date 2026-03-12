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
                        VStack(alignment: .leading, spacing: 6) {
                            if let title = observation.title, !title.isEmpty {
                                Text(title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            Text(observation.body)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }

                        if observation.id != topObservations.last?.id {
                            Divider()
                        }
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
