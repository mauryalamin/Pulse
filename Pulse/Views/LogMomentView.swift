//
//  LogMomentView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import SwiftUI
import SwiftData

struct LogMomentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    
    // Moment Components
    @State private var selectedVice: Vice? = nil
    @State private var selectedIntensity: Int? = nil
    @State private var gaveIn = false
    @State private var noteText: String = ""
    @State private var moment: Moment?
    
    @State private var showConfirmation: Bool = false
    
    private func logMoment() {
        guard let vice = selectedVice, let intensity = selectedIntensity else { return }

        let newMoment = Moment (
            timestamp: Date(),
            vice: vice,
            intensity: intensity,
            gaveIn: gaveIn,
            note: noteText.isEmpty ? nil : noteText
        )

        context.insert(newMoment)
        try? context.save()

        moment = newMoment
        showConfirmation = true

        // ✅ Async reset after delay
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            showConfirmation = false
            resetForm()
        }
    }
    
    private func resetForm() {
            selectedVice = nil
            selectedIntensity = nil
            gaveIn = false
            noteText = ""
        }
    
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
                            ViceMenuView(selectedVice: $selectedVice)
                        }
                        
                        // Intensity
                        HStack (spacing: 24) {
                            VStack (alignment: .leading, spacing: 12){
                                Text("How strong is the urge?")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                IntensityGroupView(selectedIntensity: $selectedIntensity)
                            }
                            Divider()
                            VStack (alignment: .leading, spacing: 12) {
                                Text("Urge\rFollowed?")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Toggle("Filter", isOn: $gaveIn)
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
                            TextField("Anything else you'd like to note?", text: $noteText, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack {
                            Spacer()
                            VStack (spacing: 24) {
                                Button("Save Moment") {
                                    
                                    logMoment()
                                    
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
