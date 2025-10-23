//
//  SaveMomentBar.swift
//  Pulse
//
//  Created by Maury Alamin on 10/23/25.
//

import SwiftUI

struct SaveMomentBar: View {
    let canSave: Bool
    let isSaving: Bool
    let onTap: () async -> Void

    private enum Mode: Hashable { case disabled, active, saving }

    private var mode: Mode {
        isSaving ? .saving : (canSave ? .active : .disabled)
    }

    var body: some View {
        HStack {
            content
                // Gentle visual feedback on state changes
                .scaleEffect(mode == .saving ? 0.98 : 1.0)         // slight press-in while saving
                .opacity(mode == .disabled ? 0.9 : 1.0)            // slightly muted when disabled
                .animation(.spring(response: 0.25, dampingFraction: 0.9), value: mode)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // Keep the branching tiny so the tree stays shallow
    @ViewBuilder
    private var content: some View {
        switch mode {
        case .saving:
            SavingButton()
        case .active:
            ActiveButton {
                Task { await onTap() }
            }
        case .disabled:
            DisabledButton()
        }
    }
}

// MARK: - Pieces (unchanged visuals from your version)

private struct ActiveButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Capsule().frame(width: 200, height: 50)
                HStack(spacing: 8) {
                    Text("Save Moment")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .glassEffect(.clear.interactive().tint(.pulseBlue.opacity(0.8)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Save Moment")
    }
}

private struct SavingButton: View {
    var body: some View {
        Button(action: {}) {
            ZStack {
                Capsule().frame(width: 200, height: 50)
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
            .glassEffect(.clear.interactive().tint(.pulseBlue.opacity(0.6)))
        }
        .buttonStyle(.plain)
        .disabled(true)
        .accessibilityLabel("Saving…")
    }
}

private struct DisabledButton: View {
    var body: some View {
        Button(action: {}) {
            ZStack {
                Capsule().frame(width: 200, height: 50)
                HStack(spacing: 8) {
                    Text("Save Moment")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .glassEffect(.clear.interactive().tint(.secondary.opacity(0.9)))
        }
        .buttonStyle(.plain)
        .disabled(true)
        .accessibilityLabel("Save Moment (disabled)")
        .accessibilityHint("Complete required fields to save")
    }
}

#Preview {
    SaveMomentBar(canSave: true, isSaving: false, onTap: {})
        .padding()
        .background(Color(.systemGroupedBackground))
}
