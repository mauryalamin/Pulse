//
//  HomeView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import SwiftUI
import SwiftData

@MainActor
struct HomeView: View {
    // Style Navigation Title (kept as-is)
    init() {
        var titleFont = UIFont.preferredFont(forTextStyle: .largeTitle)
        titleFont = UIFont(
            descriptor: titleFont.fontDescriptor
                .withDesign(.rounded)?
                .withSymbolicTraits(.traitBold)
            ?? titleFont.fontDescriptor,
            size: titleFont.pointSize
        )
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor(named: "PulseBlue") ?? UIColor.blue,
            .font: titleFont
        ]
    }

    // MARK: - Env
    @Environment(\.modelContext) private var context
    @Environment(AppLockManager.self) private var lock

    // MARK: - State
    @State private var isShowingLogMomentSheet = false
    @State private var showFilterSheet = false

    // Drive UI from VM (created once we have the real ModelContext)
    @State private var vm: MomentsListViewModel?

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.grayBackground).ignoresSafeArea()

                if let vm {
                    content(vm)
                } else {
                    ProgressView().task { await installVMIfNeeded() }
                }
            }
            .navigationTitle("Moments")
            .task { await vm?.reload() }
            // Log sheet
            .sheet(isPresented: $isShowingLogMomentSheet, onDismiss: {
                Task { await vm?.reload() }      // refresh once after saving
            }) {
                LogMomentView()
            }
            // Filter sheet (plumb your bindings as needed)
            .sheet(isPresented: $showFilterSheet) {
                MomentFilterSheetView(
                    selectedUrge: .constant(nil),
                    selectedTag: .constant(nil),
                    selectedIntensity: .constant(nil),
                    stayedPresentOnly: .constant(false),
                    followedOnly: .constant(false)
                )
                .presentationDetents([.medium, .large])
            }
            .onReceive(NotificationCenter.default.publisher(for: .momentDidSave)) { _ in
                Task { await vm?.reload() }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showFilterSheet = true } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) { debugToolbar() }
            }
            // Lock overlay (Observation-based)
            .overlay {
                if lock.shouldLockUI {
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterial) { EmptyView() }
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: lock.shouldLockUI)
                }
            }
            // Initial load
            .task { await installVMIfNeeded(); await vm?.reload() }
            .onAppear {
                dumpAllMoments("onAppear")
            }
        }
    }

    // MARK: - Content
    @ViewBuilder
    private func content(_ vm: MomentsListViewModel) -> some View {
        VStack {
            InsightsTeaserView(snapshot: vm.insightsSnapshot) {
                // Story 3 will route this to the full Insights screen.
            }
            .padding(.horizontal)

            if !vm.moments.isEmpty {
                headerLabel(filtersActive: filtersAreActive(vm))
            }

            // Timeline
            List {
                ForEach(vm.moments) { moment in
                    NavigationLink(value: moment) {
                        MomentListRowView(moment: moment)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let m = vm.moments[index]
                        context.delete(m)
                    }
                    try? context.save()
                    Task { await vm.reload() }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
        }
        .navigationDestination(for: Moment.self) { moment in
            MomentDetailView(moment: moment)
        }
        // Floating log button
        .overlay(alignment: .bottom) {
            Button(action: { isShowingLogMomentSheet.toggle() }) {
                LogMomentButton(size: 72, fontSize: 28)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)
        }
        // Empty states
        .overlay {
            if vm.moments.isEmpty {
                EmptyStateView(action: { isShowingLogMomentSheet.toggle() })
                    .offset(y: -40)
            }
        }
    }

    // MARK: - Helpers
    private func filtersAreActive(_ vm: MomentsListViewModel) -> Bool {
        !vm.searchText.isEmpty ||
        !vm.selectedUrgeIDs.isEmpty ||
        vm.minIntensity != 1 ||
        vm.maxIntensity != 5 ||
        vm.stayedPresentOnly
    }

    @ViewBuilder
    private func headerLabel(filtersActive: Bool) -> some View {
        VStack(alignment: .leading) {
            Text(filtersActive ? "FILTERED MOMENTS" : "ALL MOMENTS")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.pulseBlue)
        }
        .padding(.top)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func installVMIfNeeded() async {
        guard vm == nil else { return }
        vm = MomentsListViewModel(context: context)
    }

    private func dumpAllMoments(_ tag: String) {
        do {
            let all = try context.fetch(FetchDescriptor<Moment>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)]))
            print("📊 [\(tag)] total moments in store:", all.count)
            if let first = all.first {
                print("   ↳ newest:", first.timestamp, "urge:", first.urge.name, "int:", first.intensity, "gaveIn:", first.gaveIn)
            }
        } catch {
            print("❌ dumpAllMoments error:", error)
        }
    }

    @ViewBuilder
    private func debugToolbar() -> some View {
        Button {
            dumpAllMoments("onTap")
        } label: {
            Image(systemName: "tray.full")
        }
    }
}

// MARK: - Previews
#Preview("Empty State") {
    HomeView()
        .environment(AppLockManager.shared)
        .modelContainer(for: [Moment.self, Urge.self, Tag.self], inMemory: true)
}

#Preview("With Moments") {
    let container = try! ModelContainer(
        for: Moment.self, Urge.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
    container.mainContext.insert(urge)

    let moment = Moment(
        timestamp: .now,
        urge: urge,
        intensity: 4,
        gaveIn: false,
        note: "Felt the urge after work"
    )
    container.mainContext.insert(moment)

    return HomeView()
        .environment(AppLockManager.shared)
        .modelContainer(container)
}
