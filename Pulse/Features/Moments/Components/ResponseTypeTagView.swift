//
//  ResponseTypeTagView.swift
//  Pulse
//
//  Created by Maury Alamin on 10/18/25.
//

import SwiftUI

struct ResponseTypeTagView: View {
    
    var iGaveIn: Bool
    
    var body: some View {
        HStack (alignment: .center, spacing: 4) {
            Image(systemName: iGaveIn ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                .fontWeight(.regular)
            Text(iGaveIn ? "Gave In" : "Stayed Present")
                .fontWeight(.semibold)
        }
        .font(.footnote)
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(iGaveIn ? Color.gaveIn : Color.sageGreen)
        .clipShape(Capsule())
    }
}

#Preview ("Stayed Present") {
    ResponseTypeTagView(iGaveIn: false)
}

#Preview ("Gave In") {
    ResponseTypeTagView(iGaveIn: true)
}
