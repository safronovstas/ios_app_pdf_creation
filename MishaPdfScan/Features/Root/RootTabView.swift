//
//  RootTabView.swift
//  MishaPdfScan
//
//  Created by mac air on 9/3/25.
//


// =====================================
// Features/Root/RootTabView.swift — нижние вкладки
// =====================================
import SwiftUI


struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
