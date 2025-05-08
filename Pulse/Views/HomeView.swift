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
    @State private var isShowingLogMomentSheet = false
    @State private var momentToEdit: Moment?
    // @Query(sort: \Moment.timestamp) var moments: [Moment]
    var moments: [Moment] = [Moment(vice: Vice(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 3, gaveIn: false),
                             Moment(vice: Vice(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 1, gaveIn: false),
                             Moment(vice: Vice(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 5, gaveIn: true),
                             Moment(vice: Vice(name: "Cannabis", colorHex: "#6C8E3F"), intensity: 3, gaveIn: true),
                             Moment(vice: Vice(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 3, gaveIn: false),
                             Moment(vice: Vice(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 2, gaveIn: false),
                             Moment(vice: Vice(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 4, gaveIn: false),
                             Moment(vice: Vice(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 1, gaveIn: true),
                             Moment(vice: Vice(name: "Alcohol", colorHex: "#8B3A3A"), intensity: 2, gaveIn: false)]
    
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
                    List {
                        ForEach(moments) { moment in
                            MomentListRowView(moment: moment)
                            .onTapGesture {
                                momentToEdit = moment
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
                
                Button {
                    isShowingLogMomentSheet.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.pulseBlue)
                            .frame(width: 72, height: 72)
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
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
                        isShowingLogMomentSheet.toggle()
                    } label: {
                        Label("Log Moment", systemImage: "plus")
                    }
                    
                }
            }
            .overlay {
                if moments.isEmpty {
                    ContentUnavailableView("Every journey begins with noticing",
                                           systemImage: "square.and.arrow.up.circle.fill",
                                           description: Text("Pulse is ready whenever you are"))
                }
            }
            
            
        }
    }
}

#Preview {
    HomeView()
}
