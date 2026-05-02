//
//  ContentView.swift
//  BusStop
//
//  Created by Barry Dunn on 5/1/26.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject var router: Router
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Picker("", selection: $router.selectedTab) {
                    Text("Items").tag(Router.Tab.list)
                    Text("Study").tag(Router.Tab.study)
                }
                .pickerStyle(.segmented)

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .frame(width: 36, height: 32)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)

            ZStack {
                FolderListView()
                    .opacity(router.selectedTab == .list ? 1 : 0)
                    .allowsHitTesting(router.selectedTab == .list)

                StudyView()
                    .opacity(router.selectedTab == .study ? 1 : 0)
                    .allowsHitTesting(router.selectedTab == .study)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}
