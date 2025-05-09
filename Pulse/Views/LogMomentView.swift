//
//  LogMomentView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import SwiftUI
import SwiftData

struct LogMomentView: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    
    @State private var moment: Moment?
    @State private var vice: String = ""
    @State private var timestamp: Date = .now
    @State private var intensity: String = ""
    
    func setViceAs(_ thisVice: String) {
        vice = thisVice
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack (alignment: .leading){
                    VStack (alignment: .leading){
                        Text("What are you craving?")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        ViceMenuView()
                    }

                    Text("How strong is the urge?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("Log Moment")
        }
    }
}

#Preview {
    LogMomentView()
}
