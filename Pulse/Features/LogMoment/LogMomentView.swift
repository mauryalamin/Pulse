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

@MainActor
struct LogMomentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // iOS 26 Observation-based managers
    @State private var locationManager = LocationManager.shared
    
    // ViewModel (Observation)
    @State private var vm: LogMomentViewModel
    
    @State private var weatherVM = WeatherNowViewModel(
        weather: OpenMeteoWeatherService(),
        location: LocationManager.shared
    )
    
    private var canSave: Bool { !saveDisabled() }
    
    // Queries to populate pickers
    @Query(sort: \Urge.name) private var urges: [Urge]
    @Query(sort: \Tag.name)  private var tags:  [Tag]
    
    // Local UI-only state
    @State private var showConfirmation = false
    @State private var showingAlert = false
    @State private var showTagPicker = false
    
    @State private var notesFocused: Bool = false
    
    private enum FieldAnchor: Hashable { case notes }
    
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
                
                ScrollViewReader { proxy in
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
                                    IntensityGroupView(
                                        selectedIntensity: $vm.intensity,          // or $vm.intensity
                                        baseHex: vm.selectedUrge?.colorHex                // or
                                    )
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
                                TagsFlowSection(selectedTags: $vm.selectedTags, showTagPicker: $showTagPicker)
                            }
                            
                            // MARK: - Notes
                            VStack(alignment: .leading, spacing: 12) {
                                
                                notesSection()
                            }
                            
                            Divider().padding(.top, 4)
                            
                            // MARK: -  "Around This Moment" Contextual Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Around This Moment")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                // MARK: - Date and Time
                                CurrentDateTimeView()
                                
                                // MARK: - Weather
                                WeatherNowRow(state: weatherVM.state)
                                
                                // MARK: - Location
                                let isAuth = locationManager.authorizationStatus == .authorizedWhenInUse
                                || locationManager.authorizationStatus == .authorizedAlways
                                
                                let locationLabel = LocationFormatter.displayName(
                                    placename: locationManager.placename,                                  // <-- String?
                                    lat: locationManager.location?.coordinate.latitude,                    // <-- Double?
                                    lon: locationManager.location?.coordinate.longitude,                   // <-- Double?
                                    isAuthorized: isAuth
                                )
                                
                                HStack (spacing: 6) {
                                    Image(systemName: "mappin.circle.fill")
                                        .accessibilityHidden(true)     // hide decorative icon
                                    
                                    Text(locationLabel)
                                        .accessibilityLabel("Location")
                                        .accessibilityValue(locationLabel)
                                }
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityElement(children: .combine)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityElement(children: .contain)  // keep children readable but grouped
                            .accessibilityHint("Contextual information for this moment.")
                            
                            Divider()
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    .scrollDismissesKeyboard(.immediately)   // Calendar-like swipe-down anywhere
                    
                    // When Notes focuses, scroll it into view immediately
                    .onChange(of: notesFocused) { _, nowFocused in
                        guard nowFocused else { return }
                        Task { @MainActor in
                            // Defer to next runloop so TextEditor has a stable size
                            try? await Task.sleep(for: .milliseconds(16))
                            withAnimation(.easeInOut(duration: 0.15)) {
                                proxy.scrollTo(FieldAnchor.notes, anchor: .bottom)
                            }
                        }
                    }
                    .task {
                        vm = LogMomentViewModel(
                            modelContext: context,   // ✅ same env context
                            createMoment: CreateMomentUseCase(weather: OpenMeteoWeatherService()),
                            location: LocationManager.shared
                        )
                        print("📦 LogMomentView VM installed with context=\(ObjectIdentifier(context))")
                    }
                    .task { weatherVM.start() }
                    .onChange(of: locationManager.location) { _, _ in
                        weatherVM.locationDidChange()
                    }
                    .onChange(of: locationManager.authorizationStatus) { _, _ in
                        weatherVM.locationDidChange()
                    }
                    .scrollDismissesKeyboard(.interactively)
                    
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
            }
            .sheet(isPresented: $showTagPicker) {
                TagPickerView(selectedTags: $vm.selectedTags)
            }
            .ignoresSafeArea(.keyboard)
            .animation(.easeInOut, value: showConfirmation)
            .navigationTitle("Log Moment")
            .safeAreaInset(edge: .bottom) {
                SaveMomentBar(
                    canSave: vm.canSave,
                    isSaving: vm.isSaving,
                    onTap: { await onSaveTapped() }
                )
            }
            // Prevent accidental sheet-dismiss while typing; swipe down first hides keyboard
            .interactiveDismissDisabled(notesFocused)
            
            // Top Toolbar
            .toolbar {
                // Cancel
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .symbolRenderingMode(.monochrome)
                            .font(.headline)
                    }
                    .accessibilityLabel("Cancel")
                }
                
                // Save
                ToolbarItem(placement: .topBarTrailing) {
                    saveToolbarButton()
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        notesFocused = false     // drops focus → keyboard hides
                    }
                    .font(.body.weight(.semibold))
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
    
    @ViewBuilder
    private func saveToolbarButton() -> some View {
        let label = Image(systemName: "checkmark")
            .symbolRenderingMode(.monochrome)
            .font(.headline)
            .frame(minWidth: 28, minHeight: 28)
        
        if canSave {
            Button {
                Task { await onSaveTapped() }
            } label: { label }
                .buttonStyle(.glassProminent)      // glass blue when enabled
                .tint(.accentColor)
                .accessibilityLabel("Save")
        } else {
            Button {} label: { label }          // inert when disabled
                .buttonStyle(.plain)                // gray look (Mail-style)
                .tint(.secondary)
                .opacity(0.45)
                .disabled(true)
                .accessibilityLabel("Save (disabled)")
        }
    }
    
    @ViewBuilder
    private func notesSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                Text("Optional Notes")
                    .font(.subheadline).fontWeight(.semibold)
            }
            
            // Your focus-aware editor
            NoteInputView(text: $vm.notes, isFocused: $notesFocused)
                .id(FieldAnchor.notes)
                .transaction { tx in tx.disablesAnimations = true }
        }
    }
    
    private func saveDisabled() -> Bool {
        !vm.canSave || vm.isSaving
    }
    
    private func bumpTagUsage() {
        // Keep your existing behavior, on main actor
        vm.selectedTags.forEach { $0.usageCount += 1 }
    }
    
    private func showAndDismissConfirmation() async {
        await MainActor.run { showConfirmation = true }
        try? await Task.sleep(for: .milliseconds(1200))
        await MainActor.run {
            showConfirmation = false
            dismiss()
        }
    }
    
    @MainActor
    private func onSaveTapped() async {
        guard vm.canSave else {
            await MainActor.run { showingAlert = true }
            return
        }
        print("🟡 onSaveTapped: start | canSave=\(vm.canSave) isSaving=\(vm.isSaving)")
        print("🟡 onSaveTapped: calling vm.save()")
        await vm.save()
        print("🟢 onSaveTapped: returned from vm.save(), error=\(String(describing: vm.errorMessage))")
        
        if vm.errorMessage == nil {
            await MainActor.run { bumpTagUsage() }
            await showAndDismissConfirmation()
            print("✅ onSaveTapped: finished UI updates")
        }
    }
}

#Preview {
    LogMomentView()
        .modelContainer(for: [Moment.self, Urge.self, Tag.self], inMemory: true)
}

#Preview("Around This Moment block") {
    VStack(alignment: .leading, spacing: 16) {
        Text("Around This Moment")
            .font(.title3).fontWeight(.semibold)
        CurrentDateTimeView()
        Text("📍 Location: Austin")    // stub
            .font(.footnote)
            .foregroundStyle(.secondary)
        Divider()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

