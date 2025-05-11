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
    @State private var selectedUrge: Urge? = nil
    @State private var selectedIntensity: Int? = nil
    @State private var gaveIn = false
    @State private var noteText: String = ""
    @State private var moment: Moment?
    
    @State private var showConfirmation: Bool = false
    @State private var showingAlert = false
    
    private func logMoment(onSuccess: @escaping () -> Void) {
        guard let urge = selectedUrge,
              let intensity = selectedIntensity else {
            showingAlert = true
            return
        }
        
        let newMoment = Moment (
            timestamp: Date(),
            urge: urge,
            intensity: intensity,
            gaveIn: gaveIn,
            note: noteText.isEmpty ? nil : noteText
        )
        
        context.insert(newMoment)
        try? context.save()
        
        moment = newMoment
        showConfirmation = true
        
        // Async reset after delay
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            showConfirmation = false
            resetForm()
            onSuccess()
        }
    }
    
    private func resetForm() {
        selectedUrge = nil
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
                        // Urge Picker
                        VStack (alignment: .leading, spacing: 12){
                            Text("What do you feel the urge for?")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            UrgeMenuView(selectedUrge: $selectedUrge)
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
                            Text("Optional Notes")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            TextField("Anything else you'd like to note?", text: $noteText, axis: .vertical)
                                .textFieldStyle(.plain)
                                .padding()
                                .frame(minHeight: 100, alignment: .top) // helps prevent layout thrashing
                                .background(Color(UIColor.systemGray5))
                                .cornerRadius(10)
                        }
                        
                        Divider()
                        
                        HStack {
                            Spacer()
                            VStack (spacing: 24) {
                                Button("Save Moment") {
                                    logMoment {
                                        dismiss()
                                    }
                                }
                                .alert(isPresented: $showingAlert) {
                                    Alert(title: Text("Missing Information"), message: Text("A Moment needs both an Urge Type and an Urge Intensity"), dismissButton: .default(Text("OK")))
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
                if showConfirmation {
                    ZStack {
                        Color.white.opacity(0.8)
                            .ignoresSafeArea()

                        Text("Moment Logged")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.pulseBlue)
                            .offset(y: -70)
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: showConfirmation)
            .navigationTitle("Log Moment")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        logMoment {
                            dismiss()
                        }
                        
                    }
                }
            }
        }
    }
}

#Preview {
    LogMomentView()
}
