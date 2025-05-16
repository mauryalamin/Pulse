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
    
    func logNewMoment() {
        isShowingLogMomentSheet.toggle()
    }
    
    @Environment(\.modelContext) var context
    @State private var isShowingLogMomentSheet = false
    @State private var momentToEdit: Moment?
    @Query(sort: \Moment.timestamp, order: .reverse) var moments: [Moment]
    
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
                        Text("RECENT MOMENTS")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.pulseBlue)
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // MARK: - Timeline
                    List {
                        ForEach(moments) { moment in
                            NavigationLink(value: moment) {
                                MomentListRowView(moment: moment)
                            }
                        }
                        .onDelete { IndexSet in
                            for index in IndexSet {
                                context.delete(moments[index])
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
            .sheet(item: $momentToEdit) { moment in
                UpdateMomentView(moment: moment)
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .overlay {
                if moments.isEmpty {
                    EmptyStateView(action: logNewMoment)
                        .offset(y:-40)
                }
            }
        }
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
