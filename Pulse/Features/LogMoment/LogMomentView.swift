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
                            HStack {
                                Image(systemName: "tag.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                Text("Tags")
                                    .font(.subheadline).fontWeight(.semibold)
                            }
                            
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
                            HStack {
                                Image(systemName: "text.bubble.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.green)
                                Text("Optional Notes")
                                    .font(.subheadline).fontWeight(.semibold)
                            }
                            NoteInputView(text: $vm.notes)
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
                .task {
                    // Kick off permission + first fix
                    locationManager.requestPermissionAndLocation()
                    // Recreate VM with the real ModelContext (replaces placeholder)
                    print("📦 LogMomentView .task: context=\(ObjectIdentifier(context))")
                    vm = LogMomentViewModel(
                        modelContext: context,
                        createMoment: CreateMomentUseCase(weather: OpenMeteoWeatherService()),
                        location: LocationManager.shared
                    )
                    
                }
                .task { weatherVM.start() }
                .onChange(of: locationManager.location) { _, _ in
                    weatherVM.locationDidChange()
                }
                .onChange(of: locationManager.authorizationStatus) { _, _ in
                    weatherVM.locationDidChange()
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
            .safeAreaInset(edge: .bottom) {
                SaveMomentBar(
                    canSave: !saveDisabled(),
                    isSaving: vm.isSaving,
                    onTap: { await onSaveTapped() }
                )
            }
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
        print("🟡 onSaveTapped: start | canSave=\(vm.canSave) isSaving=\(vm.isSaving)")
        
        guard !vm.isSaving else { print("🟠 onSaveTapped: blocked (isSaving)"); return }
        guard vm.canSave else {
            print("🔺 onSaveTapped: blocked (canSave=false)");
            showingAlert = true
            // Optional subtle warning haptic
            let warn = UINotificationFeedbackGenerator()
            warn.notificationOccurred(.warning)
            return
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        vm.isSaving = true
        defer { vm.isSaving = false }
        
        print("🟡 onSaveTapped: calling vm.save()")
        await vm.save()
        print("🟢 onSaveTapped: returned from vm.save(), error=\(vm.errorMessage ?? "nil")")
        
        if vm.errorMessage != nil { return }
        
        // Success haptic
        let ok = UINotificationFeedbackGenerator()
        ok.notificationOccurred(.success)
        
        bumpTagUsage()
        await showAndDismissConfirmation()
        print("✅ onSaveTapped: finished UI updates")
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
