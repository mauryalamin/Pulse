//
//  HomeView.swift
//  Pulse
//
//  Created by Maury Alamin on 5/7/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    
    @State private var isShowingLogMomentSheet = false
    
    @Query(sort: \Moment.timestamp) var moments: [Moment]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(moments) { moment in
                    VStack (alignment: .leading) {
                        Text(moment.timestamp.formatted(date: .abbreviated, time: .shortened))
                        Text(moment.vice)
                        Text("\(moment.intensity)")
                        
                    }
                }
            }
            .navigationTitle("Moments")
            .sheet(isPresented: $isShowingLogMomentSheet) { LogMomentView() }
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
