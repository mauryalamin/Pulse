//
//  HomeView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    // Style Navigation Title
    init() {
        var titleFont = UIFont.preferredFont(forTextStyle: .largeTitle) /// the default large title font
        titleFont = UIFont(
            descriptor:
                titleFont.fontDescriptor
                .withDesign(.rounded)? /// make rounded
                .withSymbolicTraits(.traitBold) /// make bold
            ??
            titleFont.fontDescriptor, /// return the normal title if customization failed
            size: titleFont.pointSize
        )
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(named: "PulseBlue") ?? UIColor.blue, .font: titleFont]
    }
    
    @Environment(\.modelContext) var context
    @EnvironmentObject var biometricManager: BiometricAuthManager
    @State private var isShowingLogMomentSheet = false
    @State private var momentToEdit: Moment?
    
    @State private var selectedUrgeFilter: Urge?
    @State private var selectedTagFilter: Tag?
    @State private var selectedIntensityFilter: Int?
    @State private var stayedPresentOnly: Bool = false
    @State private var followedOnly: Bool = false
    @State private var showFilterSheet: Bool = false
    
    @Query(sort: \Moment.timestamp, order: .reverse) private var allMoments: [Moment]
    
    private var isTrulyEmpty: Bool {
        allMoments.isEmpty
    }
    
    var filteredMoments: [Moment] {
        allMoments.filter { moment in
            (selectedUrgeFilter == nil || moment.urge.id == selectedUrgeFilter?.id) &&
            (selectedTagFilter == nil || moment.tags?.contains(where: { $0.id == selectedTagFilter?.id }) == true) &&
            (selectedIntensityFilter == nil || moment.intensity == selectedIntensityFilter) &&
            (!stayedPresentOnly || moment.gaveIn == false) &&
            (!followedOnly || moment.gaveIn == true)
        }
    }
    
    func logNewMoment() {
        isShowingLogMomentSheet.toggle()
    }
    
    var body: some View {
        NavigationStack {
            ZStack (alignment: .bottom){
                Color(.grayBackground)
                    .ignoresSafeArea()
                VStack {
                    HStack {
                        FactoidGroupView()
                        Spacer()
                        Divider().frame(width: 1)
                        Button {
                            showFilterSheet = true
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.largeTitle)
                                .fontWeight(.light)
                        }
                    }
                    .frame(height: 50)
                    .padding(.horizontal)
                    
                    // MARK: - Header
                    VStack (alignment: .leading) {
                        Text(filtersAreActive ? "FILTERED MOMENTS" : "ALL MOMENTS")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.pulseBlue)
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // MARK: - Timeline
                    List {
                        ForEach(filteredMoments) { moment in
                            NavigationLink(value: moment) {
                                MomentListRowView(moment: moment)
                            }
                        }
                        .onDelete { IndexSet in
                            for index in IndexSet {
                                context.delete(filteredMoments[index])
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
                .navigationDestination(for: Moment.self) { moment in
                    MomentDetailView(moment: moment)
                }
                Button {
                    logNewMoment()
                } label: {
                    LogMomentButton(size: 72, fontSize: 28)
                }
                .buttonStyle(PlainButtonStyle())
                .shadow(radius: 12)
                
            }
            .navigationTitle("Moments")
            .sheet(isPresented: $isShowingLogMomentSheet) { LogMomentView() }
            .sheet(isPresented: $showFilterSheet) {
                MomentFilterSheetView(
                    selectedUrge: $selectedUrgeFilter,
                    selectedTag: $selectedTagFilter,
                    selectedIntensity: $selectedIntensityFilter,
                    stayedPresentOnly: $stayedPresentOnly,
                    followedOnly: $followedOnly
                )
                .presentationDetents([.medium, .large])
            }
            .toolbar {
                ToolbarItem (placement: .navigationBarLeading)  {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem (placement: .navigationBarTrailing)  {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .overlay {
                if filteredMoments.isEmpty {
                    if isTrulyEmpty {
                        EmptyStateView(action: logNewMoment)
                            .offset(y: -40)
                    } else {
                        VStack(spacing: 12) {
                            Text("No moments match your filters.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Button("Clear Filters") {
                                selectedUrgeFilter = nil
                                selectedTagFilter = nil
                                selectedIntensityFilter = nil
                                stayedPresentOnly = false
                                followedOnly = false
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.top, 64)
                    }
                }
            }
            .overlay {
                if !biometricManager.isUnlocked {
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterial) {
                        EmptyView()
                    }
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: biometricManager.isUnlocked)
                }
            }
        }
    }
}

private extension HomeView {
    var filtersAreActive: Bool {
        selectedUrgeFilter != nil ||
        selectedTagFilter != nil ||
        selectedIntensityFilter != nil ||
        stayedPresentOnly ||
        followedOnly
    }
}


#Preview("Empty State") {
    HomeView()
        .modelContainer(for: [Moment.self, Urge.self], inMemory: true)
}

#Preview("With Moments") {
    let container = try! ModelContainer(
        for: Moment.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let urge = Urge(name: "Alcohol", colorHex: "#8B3A3A")
    container.mainContext.insert(urge)
    
    let moment = Moment (
        timestamp: .now,
        urge: urge,
        intensity: 4,
        gaveIn: false,
        note: "Felt the urge after work"
    )
    container.mainContext.insert(moment)
    
    return HomeView()
        .modelContainer(container)
}
