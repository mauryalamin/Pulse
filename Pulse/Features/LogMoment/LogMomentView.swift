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
    
    // Managers (Observation)
    @State private var locationManager = LocationManager.shared
    
    // ViewModel is installed once we have the real ModelContext
    @State private var vm: LogMomentViewModel? = nil
    
    // Weather row
    @State private var weatherVM = WeatherNowViewModel(
        weather: OpenMeteoWeatherService(),
        location: LocationManager.shared
    )
    
    // Queries to populate pickers
    @Query(sort: \Urge.name) private var urges: [Urge]
    @Query(sort: \Tag.name)  private var tags:  [Tag]
    
    // Local UI state
    @State private var showConfirmation = false
    @State private var showingAlert = false
    @State private var showTagPicker = false
    @State private var notesFocused = false
    
    private enum FieldAnchor: Hashable { case notes }
    
    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    content(vm)
                } else {
                    // Lightweight placeholder while we install the VM with real ModelContext
                    ProgressView()
                        .task {
                            // Install the real VM once (no in-memory store involved)
                            self.vm = LogMomentViewModel(
                                modelContext: context,
                                createMoment: CreateMomentUseCase(weather: OpenMeteoWeatherService()),
                                location: LocationManager.shared
                            )
                            print("📦 LogMomentView VM installed with context=\(ObjectIdentifier(context))")
                        }
                        .task { weatherVM.start() }
                }
            }
        }
    }
    
    // MARK: - Main content (uses @Bindable for clean bindings)
    @ViewBuilder
    private func content(_ concrete: LogMomentViewModel) -> some View {
        @Bindable var vm = concrete
        
        ZStack {
            Color(.grayBackground).ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // MARK: - Urge Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What do you feel the urge for?")
                                .font(.subheadline).fontWeight(.semibold)
                            UrgeMenuView(selectedUrge: $vm.selectedUrge)
                        }
                        
                        // MARK: - Intensity + Followed
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("How strong is the urge?")
                                    .font(.subheadline).fontWeight(.semibold)
                                IntensityGroupView(
                                    selectedIntensity: $vm.intensity,
                                    baseHex: vm.selectedUrge?.colorHex
                                )
                            }
                            Divider()
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Urge\rFollowed?")
                                    .font(.subheadline).fontWeight(.semibold)
                                Toggle("Filter", isOn: Binding(
                                    get: { vm.response.gaveIn },
                                    set: { vm.response = $0 ? .followed : .stayedPresent }
                                ))
                                .labelsHidden()
                            }
                        }
                        
                        // MARK: - Tags (keeps your custom flow layout)
                        VStack(alignment: .leading, spacing: 12) {
                            TagsFlowSection(
                                selectedTags: $vm.selectedTags,
                                showTagPicker: $showTagPicker
                            )
                        }
                        
                        // MARK: - Notes
                        notesSection(vm: vm)
                            .id(FieldAnchor.notes)
                        
                        Divider().padding(.top, 4)
                        
                        // MARK: - Around This Moment
                        contextualSection
                        Divider()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: notesFocused) { _, nowFocused in
                    guard nowFocused else { return }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(16))
                        withAnimation(.easeInOut(duration: 0.15)) {
                            proxy.scrollTo(FieldAnchor.notes, anchor: .bottom)
                        }
                    }
                }
            }
            
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
        
        // Bottom save bar (unchanged visuals/logic)
        .safeAreaInset(edge: .bottom) {
            SaveMomentBar(
                canSave: vm.canSave && !vm.isSaving,
                isSaving: vm.isSaving,
                onTap: { await onSaveTapped(vm) }
            )
        }
        
        .interactiveDismissDisabled(notesFocused)
        
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .symbolRenderingMode(.monochrome)
                        .font(.headline)
                }
                .accessibilityLabel("Cancel")
            }
            ToolbarItem(placement: .topBarTrailing) {
                saveToolbarButton(vm: vm)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { notesFocused = false }
                    .font(.body.weight(.semibold))
            }
        }
        
        // Errors from VM save
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        
        // Weather refresh hooks
        .onChange(of: locationManager.location)            { _, _ in weatherVM.locationDidChange() }
        .onChange(of: locationManager.authorizationStatus) { _, _ in weatherVM.locationDidChange() }
        // LogMomentView.swift (inside body)
        .task {
            // Preflight location ONCE when the sheet appears
            locationManager.preflightAuthorization()
            locationManager.refreshIfAuthorized()   // optional nudge
        }
        
        // If you kick off weather, only do so after auth changes or fixes:
        .onChange(of: locationManager.authorizationStatus) { _, _ in
            weatherVM.locationDidChange()
        }
        .onChange(of: locationManager.location) { _, _ in
            weatherVM.locationDidChange()
        }
        .task { weatherVM.start() }
    }
    
    // MARK: - Pieces preserved
    
    @ViewBuilder
    private func notesSection(vm: LogMomentViewModel) -> some View {
        @Bindable var vm = vm
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                Text("Optional Notes")
                    .font(.subheadline).fontWeight(.semibold)
            }
            NoteInputView(text: $vm.notes, isFocused: $notesFocused)
                .transaction { tx in tx.disablesAnimations = true }
        }
    }
    
    @ViewBuilder
    private var contextualSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Around This Moment")
                .font(.title3).fontWeight(.semibold)
            
            CurrentDateTimeView()
            WeatherNowRow(state: weatherVM.state)
            
            let isAuth = locationManager.authorizationStatus == .authorizedWhenInUse
            || locationManager.authorizationStatus == .authorizedAlways
            
            let locationLabel = LocationFormatter.displayName(
                placename: locationManager.placename,
                lat: locationManager.location?.coordinate.latitude,
                lon: locationManager.location?.coordinate.longitude,
                isAuthorized: isAuth
            )
            
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .accessibilityHidden(true)
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
        .accessibilityElement(children: .contain)
        .accessibilityHint("Contextual information for this moment.")
    }
    
    @ViewBuilder
    private func saveToolbarButton(vm: LogMomentViewModel) -> some View {
        let enabled = vm.canSave && !vm.isSaving
        let label = Image(systemName: "checkmark")
            .symbolRenderingMode(.monochrome)
            .font(.headline)
            .frame(minWidth: 28, minHeight: 28)
        
        if enabled {
            Button { Task { await onSaveTapped(vm) } } label: { label }
                .buttonStyle(.glassProminent)
                .tint(.accentColor)
                .accessibilityLabel("Save")
        } else {
            Button {} label: { label }
                .buttonStyle(.plain)
                .tint(.secondary)
                .opacity(0.45)
                .disabled(true)
                .accessibilityLabel("Save (disabled)")
        }
    }
    
    private func bumpTagUsage(vm: LogMomentViewModel) {
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
    private func onSaveTapped(_ vm: LogMomentViewModel) async {
        guard vm.canSave else {
            showingAlert = true
            return
        }
        print("🟡 onSaveTapped: start | canSave=\(vm.canSave) isSaving=\(vm.isSaving)")
        print("🟡 onSaveTapped: calling vm.save()")
        await vm.save()
        print("🟢 onSaveTapped: returned from vm.save(), error=\(String(describing: vm.errorMessage))")
        
        if vm.errorMessage == nil {
            bumpTagUsage(vm: vm)
            await showAndDismissConfirmation()
            print("✅ onSaveTapped: finished UI updates")
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
        }
    }
}

// MARK: - Previews
#Preview {
    LogMomentView()
    // Previews can stay in-memory; app build uses the real persistent store
        .modelContainer(for: [Moment.self, Urge.self, Tag.self], inMemory: true)
}
