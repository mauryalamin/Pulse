//
//  HomeView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Init (nav title styling + placeholder VM)
    init() {
        var titleFont = UIFont.preferredFont(forTextStyle: .largeTitle)
        titleFont = UIFont(
            descriptor:
                titleFont.fontDescriptor
                .withDesign(.rounded)?
                .withSymbolicTraits(.traitBold)
            ?? titleFont.fontDescriptor,
            size: titleFont.pointSize
        )
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor(named: "PulseBlue") ?? UIColor.blue,
            .font: titleFont
        ]

        let tempContainer = try! ModelContainer(
            for: Moment.self, Urge.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        _vm = State(initialValue: MomentsListViewModel(context: ModelContext(tempContainer)))
    }

    // MARK: - Env / State
    @Environment(\.modelContext) private var context
    @Environment(AppLockManager.self) private var lock

    @State private var vm: MomentsListViewModel
    @State private var momentsRaw: [Moment] = []   // fetched via SwiftData
    @State private var moments: [Moment] = []      // after client-side filters

    @State private var isShowingLogMomentSheet = false
    @State private var showFilterSheet = false

    // Filter UI (existing)
    @State private var selectedUrgeFilter: Urge?
    @State private var selectedTagFilter: Tag?
    @State private var selectedIntensityFilter: Int?
    @State private var stayedPresentOnly: Bool = false
    @State private var followedOnly: Bool = false
    
    private var filtersAreActive: Bool {
        selectedUrgeFilter != nil ||
        selectedTagFilter != nil ||
        selectedIntensityFilter != nil ||
        stayedPresentOnly ||
        followedOnly
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.grayBackground).ignoresSafeArea()

                VStack {
                    topRow()
                    headerLabel()
                    timelineList()
                }
                .navigationDestination(for: Moment.self) { moment in
                    MomentDetailView(moment: moment)
                }

                floatingLogButton()
            }
            .navigationTitle("Moments")
            // Sheet for LogMomentView
            .sheet(isPresented: $isShowingLogMomentSheet) {
                LogMomentView()
            }
            .onChange(of: isShowingLogMomentSheet) { _, shown in
                if !shown { Task { await refreshQuery() } }   // refresh when sheet is dismissed
            }
            .sheet(isPresented: $showFilterSheet) { filterSheet() }
            .toolbar { toolbarContent() }
            .overlay { emptyStateOverlay() }
            .overlay { lockOverlay() }
            .task { await initialLoad() }
            .onChange(of: selectedIntensityFilter) { _, _ in onServerFilterChanged() }
            .onChange(of: stayedPresentOnly) { _, _ in onStayedPresentChanged() }
            .onChange(of: selectedUrgeFilter) { _, _ in applyClientFiltersOnly() }
            .onChange(of: selectedTagFilter) { _, _ in applyClientFiltersOnly() }
            .onChange(of: followedOnly) { _, _ in onFollowedOnlyChanged() }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func topRow() -> some View {
        HStack {
            FactoidGroupView()
            Spacer()
            Divider().frame(width: 1)
            Button { showFilterSheet = true } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.largeTitle)
                    .fontWeight(.light)
            }
        }
        .frame(height: 50)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func headerLabel() -> some View {
        VStack(alignment: .leading) {
            Text(filtersAreActive ? "FILTERED MOMENTS" : "ALL MOMENTS")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.pulseBlue)
        }
        .padding(.top)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func timelineList() -> some View {
        List {
            ForEach(moments) { moment in
                NavigationLink(value: moment) {
                    MomentListRowView(moment: moment)
                }
            }
            .onDelete { indexSet in
                for index in indexSet { context.delete(moments[index]) }
                try? context.save()
                Task { await refreshQuery() }
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func floatingLogButton() -> some View {
        Button(action: { isShowingLogMomentSheet = true }) {
            LogMomentButton(size: 72, fontSize: 28)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func lockOverlay() -> some View {
        if !lock.isUnlocked {
            VisualEffectBlur(blurStyle: .systemUltraThinMaterial) { EmptyView() }
                .ignoresSafeArea()
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: lock.isUnlocked)
        }
    }

    @ViewBuilder
    private func emptyStateOverlay() -> some View {
        let trulyEmpty = momentsRaw.isEmpty
        if moments.isEmpty {
            if trulyEmpty {
                EmptyStateView(action: { isShowingLogMomentSheet = true })
                    .offset(y: -40)
            } else {
                VStack(spacing: 12) {
                    Text("No moments match your filters.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("Clear Filters") {
                        clearFilters()
                        Task { await refreshQuery() }
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.top, 64)
            }
        }
    }

    @ViewBuilder
    private func filterSheet() -> some View {
        MomentFilterSheetView(
            selectedUrge: $selectedUrgeFilter,
            selectedTag: $selectedTagFilter,
            selectedIntensity: $selectedIntensityFilter,
            stayedPresentOnly: $stayedPresentOnly,
            followedOnly: $followedOnly
        )
        .presentationDetents([.medium, .large])
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading)  {
            Button { showFilterSheet = true } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink { SettingsView() } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }

    // MARK: - Data

    @MainActor
    private func fetchMoments() -> [Moment] {
        let sort = [SortDescriptor(\Moment.timestamp, order: .reverse)]
        let fd = FetchDescriptor<Moment>(predicate: vm.predicate, sortBy: sort)
        return (try? context.fetch(fd)) ?? []
    }

    @MainActor
    private func refreshQuery() async {
        momentsRaw = fetchMoments()
        applyClientFiltersOnly()
    }

    private func applyClientFiltersOnly() {
        var out: [Moment] = momentsRaw

        if let urge = selectedUrgeFilter {
            out = out.filter { $0.urge.id == urge.id }
        }
        if let tag = selectedTagFilter {
            out = out.filter { ($0.tags?.contains { $0.id == tag.id }) == true }
        }
        if let exact = selectedIntensityFilter {
            out = out.filter { $0.intensity == exact }
        }
        if followedOnly {
            out = out.filter { $0.gaveIn == true }
        }

        moments = out
    }

    private func propagateFiltersToVM() {
        if let exact = selectedIntensityFilter {
            vm.minIntensity = exact
            vm.maxIntensity = exact
        } else {
            vm.minIntensity = 1
            vm.maxIntensity = 5
        }
        vm.stayedPresentOnly = stayedPresentOnly
        if let urge = selectedUrgeFilter {
            vm.selectedUrges = [urge.id]
        } else {
            vm.selectedUrges = []
        }
    }

    private func clearFilters() {
        selectedUrgeFilter = nil
        selectedTagFilter = nil
        selectedIntensityFilter = nil
        stayedPresentOnly = false
        followedOnly = false
        propagateFiltersToVM()
    }

    // MARK: - Lifecycle / Change handlers

    private func onServerFilterChanged() {
        propagateFiltersToVM()
        Task { await refreshQuery() }
    }

    private func onStayedPresentChanged() {
        if stayedPresentOnly { followedOnly = false }
        onServerFilterChanged()
    }

    private func onFollowedOnlyChanged() {
        if followedOnly { stayedPresentOnly = false }
        applyClientFiltersOnly()
    }

    private func initialLoad() async {
        vm = MomentsListViewModel(context: context)
        propagateFiltersToVM()
        await refreshQuery()
    }
}

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
