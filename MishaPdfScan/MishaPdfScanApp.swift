import SwiftUI


@main
struct MishaPdfScanApp: App {
    @StateObject private var pagesStore = PagesStore()
    @StateObject private var historyStore = HistoryStore()
    
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(pagesStore)
                .environmentObject(historyStore)
        }
    }
}
