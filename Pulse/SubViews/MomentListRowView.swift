//
//  MomentListRowView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/8/25.
//

import SwiftUI

struct MomentListRowView: View {
    
    let moment: Moment
    
    
    
    var body: some View {
        HStack {
            VStack (alignment: .leading) {
                Text(moment.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .padding(.vertical, 4)
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color(hex: moment.vice.colorHex) ?? .gray)
                            .frame(width: 34, height: 34)
                        Text("\(moment.intensity)")
                            .foregroundStyle(.white)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Text(moment.vice.name)
                        .font(.body)
                }
            }
            Spacer()
            HStack {
                Image(systemName: moment.gaveIn ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(moment.gaveIn ? .gaveIn : .sageGreen)
            }
        }
    }
}

#Preview {
    MomentListRowView(moment: Moment(vice: Vice(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 4, gaveIn: false))
}
