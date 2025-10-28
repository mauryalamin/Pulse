//
//  NoteInputView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/12/25.
//

import SwiftUI

@MainActor
struct NoteInputView: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    var placeholder: String = "Anything else you'd like to note?"
    
    @FocusState private var editorFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            // Editor
            TextEditor(text: $text)
                .focused($editorFocused)
                .frame(minHeight: 120)                    // keeps it stable as keyboard appears
                .scrollContentBackground(.hidden)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .background(Color(UIColor.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(1)
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
                    .padding(.leading, 12)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            // tiny anti-jitter padding
        }
        .contentShape(Rectangle())                        // tap anywhere in the card to focus
        .onTapGesture { editorFocused = true }
        .onChange(of: isFocused) { _, newVal in           // external focus <-> internal focus
            editorFocused = newVal
        }
        .onChange(of: editorFocused) { _, newVal in
            isFocused = newVal
        }
        .accessibilityLabel("Notes")
        .accessibilityValue(text.isEmpty ? "Empty" : "Has text")
    }
}

#Preview {
    VStack(spacing: 16) {
        NoteInputView(text: .constant(""), isFocused: .constant(false))
        NoteInputView(text: .constant("Some existing note…"), isFocused: .constant(false))
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
