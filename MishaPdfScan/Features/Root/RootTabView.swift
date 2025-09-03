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
                .tabItem { Label("tab.home", systemImage: "house") }
            HistoryView()
                .tabItem { Label("tab.history", systemImage: "clock") }
            SettingsView()
                .tabItem { Label("tab.settings", systemImage: "gearshape") }
        }
    }
}

#if DEBUG
struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
            .environmentObject(PagesStore.preview(withPages: 2))
            .environmentObject(HistoryStore.previewWithSamples(count: 2))
    }
}
#endif
