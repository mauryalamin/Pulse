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
    @State private var selectedVice: Vice? = nil
    
    // @State private var vice: String = ""
    @State private var timestamp: Date = .now
    @State private var intensity: String = ""
    
    @State private var urgeFollowed = false
    @State private var notes: String = "Hello"
    
//    func setViceAs(_ thisVice: String) {
//        vice = thisVice
//    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.grayBackground)
                    .ignoresSafeArea()
                ScrollView {
                    VStack (alignment: .leading, spacing: 32){
                        // Vice Picker
                        VStack (alignment: .leading, spacing: 12){
                            Text("What are you craving?")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            ViceMenuView()
                        }
                        
                        // Intensity
                        HStack (spacing: 24) {
                            VStack (alignment: .leading, spacing: 12){
                                Text("How strong is the urge?")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                IntensityGroupView()
                            }
                            Divider()
                            VStack (alignment: .leading, spacing: 12) {
                                Text("Urge\rFollowed?")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Toggle("Filter", isOn: $urgeFollowed)
                                    .labelsHidden()
                            }
                        }
                        
                        // Add Tags
                        VStack (alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Button("Add") {
                                
                            }
                        }
                        
                        // Add Notes
                        VStack (alignment: .leading, spacing: 12) {
                            Text("Notes")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            TextField("Anything else you'd like to note?", text: $notes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack {
                            Spacer()
                            VStack (spacing: 24) {
                                Button("Save Moment") {
                                    
                                    dismiss()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                
                                Button("Cancel") {
                                    
                                    dismiss()
                                }
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
            .navigationTitle("Log Moment")
        }
    }
}

#Preview {
    LogMomentView()
}
