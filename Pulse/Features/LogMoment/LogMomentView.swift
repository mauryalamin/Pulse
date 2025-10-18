//
//  LogMomentView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import SwiftUI
import SwiftData
import CoreLocation
import Observation

struct LogMomentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // iOS 26 Observation-based managers
    @State private var keyboard = KeyboardResponder()
    @State private var locationManager = LocationManager.shared

    // ViewModel (Observation)
    @State private var vm: LogMomentViewModel

    // Queries to populate pickers
    @Query(sort: \Urge.name) private var urges: [Urge]
    @Query(sort: \Tag.name)  private var tags:  [Tag]

    // Local UI-only state
    @State private var showConfirmation = false
    @State private var showingAlert = false
    @State private var showTagPicker = false

    // Init with a placeholder VM; we’ll inject real deps in .task once we have ModelContext
    init() {
        // Build a temporary, in-memory SwiftData context just for initialization.
        // We replace this with the real Environment modelContext inside .task.
        let tempContext: ModelContext = {
            // Force-try is fine here because this is only a local, in-memory container
            let container = try! ModelContainer(
                for: Moment.self, Urge.self, Tag.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            return ModelContext(container)
        }()

        _vm = State(initialValue: LogMomentViewModel(
            modelContext: tempContext,
            createMoment: CreateMomentUseCase(weather: OpenMeteoWeatherService()),
            location: LocationManager.shared
        ))
    }


    // Bridge Toggle (gaveIn Bool) <-> VM (MomentResponse)
    private var gaveInBinding: Binding<Bool> {
        Binding<Bool>(
            get: { vm.response.gaveIn },
            set: { vm.response = $0 ? .followed : .stayedPresent }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.grayBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {

                        // MARK: - Urge Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What do you feel the urge for?")
                                .font(.subheadline).fontWeight(.semibold)
                            UrgeMenuView(selectedUrge: $vm.selectedUrge)   // uses your existing component
                        }

                        // MARK: - Intensity + Followed toggle
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("How strong is the urge?")
                                    .font(.subheadline).fontWeight(.semibold)
                                IntensityGroupView(selectedIntensity: $vm.intensity)
                            }
                            Divider()
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Urge\rFollowed?")
                                    .font(.subheadline).fontWeight(.semibold)
                                Toggle("Filter", isOn: gaveInBinding)
                                    .labelsHidden()
                            }
                        }

                        // MARK: - Tags
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.subheadline).fontWeight(.semibold)

                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 90), spacing: 6)],
                                alignment: .leading,
                                spacing: 6
                            ) {
                                ForEach(vm.selectedTags, id: \.id) { tag in
                                    TagView(tag: tag.name)
                                }

                                Button(action: { showTagPicker = true }) {
                                    Label("Add", systemImage: "plus")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 4)
                                        .background(Color.pulseBlue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .font(.subheadline)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // MARK: - Notes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Optional Notes")
                                .font(.subheadline).fontWeight(.semibold)
                            NoteInputView(text: $vm.notes)
                        }

                        Divider()

                        // MARK: - Location
                        Group {
                            if let place = locationManager.placename {
                                Text("📍 Location: \(place)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else if locationManager.authorizationStatus == .authorizedWhenInUse ||
                                      locationManager.authorizationStatus == .authorizedAlways {
                                Text("📍 Retrieving location…")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()

                        // MARK: - Button Group
                        HStack {
                            Spacer()
                            VStack(spacing: 24) {
                                Button("Save Moment") {
                                    Task {
                                        if !vm.canSave {
                                            showingAlert = true
                                            return
                                        }
                                        await vm.save()
                                        // bump tag usage (preserving your behavior)
                                        vm.selectedTags.forEach { $0.usageCount += 1 }
                                        showConfirmation = true
                                        try? await Task.sleep(for: .milliseconds(1500))
                                        showConfirmation = false
                                        dismiss()
                                    }
                                }
                                .alert(isPresented: $showingAlert) {
                                    Alert(
                                        title: Text("Missing Information"),
                                        message: Text("A Moment needs both an Urge Type and an Urge Intensity"),
                                        dismissButton: .default(Text("OK"))
                                    )
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)

                                Button("Cancel") { dismiss() }
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .task {
                    // Kick off permission + first fix
                    locationManager.requestPermissionAndLocation()
                    // Recreate VM with the real ModelContext (replaces placeholder)
                    vm = LogMomentViewModel(
                        modelContext: context,
                        createMoment: CreateMomentUseCase(weather: OpenMeteoWeatherService()),
                        location: LocationManager.shared
                    )
                }
                .safeAreaInset(edge: .bottom) {
                    Spacer().frame(height: keyboard.keyboardHeight + 40)
                }
                .scrollDismissesKeyboard(.interactively)
                .animation(.easeInOut(duration: 0.3), value: keyboard.keyboardHeight)

                // Confirmation Toast
                if showConfirmation {
                    ZStack {
                        Color.white.opacity(0.9).ignoresSafeArea()
                        VStack(alignment: .center) {
                            Image(.pulseBeat)
                                .resizable()
                                .frame(width: 153, height: 90)
                                .scaledToFit()
                            Text("Moment Logged")
                                .font(.headline)
                                .fontDesign(.rounded)
                                .fontWeight(.semibold)
                                .foregroundStyle(.pulseBlue)
                        }
                        .offset(y: -90)
                    }
                    .transition(.opacity)
                }
            }
            .sheet(isPresented: $showTagPicker) {
                TagPickerView(selectedTags: $vm.selectedTags)
            }
            .ignoresSafeArea(.keyboard)
            .animation(.easeInOut, value: showConfirmation)
            .navigationTitle("Log Moment")
            // Top Toolbar
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            if !vm.canSave {
                                showingAlert = true
                                return
                            }
                            await vm.save()
                            vm.selectedTags.forEach { $0.usageCount += 1 }
                            showConfirmation = true
                            try? await Task.sleep(for: .milliseconds(1500))
                            showConfirmation = false
                            dismiss()
                        }
                    }
                }
            }
            // VM error surfacing (if CreateMomentUseCase fails)
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }
}

#Preview {
    LogMomentView()
        .modelContainer(for: [Moment.self, Urge.self, Tag.self], inMemory: true)
}
