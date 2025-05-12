//
//  NoteInputView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/12/25.
//

import SwiftUI

struct NoteInputView: View {
    @Binding var text: String
    var placeholder: String = "Anything else you'd like to note?"
    
    var body: some View {
        ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 10)
                            .padding(.leading, 14)
                    }

                    TextEditor(text: $text)
                        .frame(minHeight: 100)
                        .frame(maxWidth: .infinity)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(.primary)
                }
                .padding(8)
                .background(Color(UIColor.systemGray5))
                .cornerRadius(10)
    }
}

#Preview {
    NoteInputView(text: .constant(""))
}
