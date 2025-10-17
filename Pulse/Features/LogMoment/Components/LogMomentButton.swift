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
                .fill(Color.pulseBlue)
                .frame(width: size, height: size)
            Image(systemName: "plus")
                //.font(.title)
                .font(.system(size: fontSize))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    LogMomentButton(size: 72, fontSize: 28)
}
