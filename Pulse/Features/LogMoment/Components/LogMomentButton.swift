//
//  LogMomentButton.swift
//  Pulse
//
//  Created by Maury Alamin on 5/8/25.
//

import SwiftUI

struct LogMomentButton: View {
    
    var size: CGFloat
    var fontSize: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: size, height: size)
            Image(systemName: "plus")
                .font(.system(size: fontSize))
                .foregroundStyle(.white)
        }
        .glassEffect(
            .clear.interactive()
                .tint(.pulseBlue.opacity(0.8))
        )
    }
}

#Preview {
    LogMomentButton(size: 72, fontSize: 28)
}
