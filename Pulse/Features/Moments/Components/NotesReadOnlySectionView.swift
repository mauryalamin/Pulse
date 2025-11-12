//
//  NotesReadOnlySectionView.swift
//  Pulse
//
//  Created by Maury Alamin on 11/12/25.
//

import SwiftUI

struct NotesReadOnlySectionView: View {
    /// Raw note string from the saved `Moment` (may be nil or whitespace-only)
    let note: String?

    /// Normalized value used for rendering (nil if effectively empty)
    private var normalizedNote: String? {
        guard let raw = note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty
        else { return nil }
        return raw
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row lives in your DetailView; this is just the content.
            if let text = normalizedNote {
                Text(text)
                    .font(.body)
                    .textSelection(.enabled) // allow copy
                    .accessibilityLabel("Notes")
                    .accessibilityValue(text)
            } else {
                Text("No notes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Notes")
                    .accessibilityValue("No notes")
            }
        }
    }
}

#Preview("Notes — has text") {
    NotesReadOnlySectionView(note: "Felt the urge after work.\nTook a walk instead.")
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Notes — empty") {
    NotesReadOnlySectionView(note: "   \n")
        .padding()
        .background(Color(.systemGroupedBackground))
}
