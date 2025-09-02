import SwiftUI

@main
struct MishaPdfScanApp: App {
    @StateObject private var store = PagesStore()

    var body: some Scene {
        WindowGroup {
            StartView()
                .environmentObject(store)   // ← даём store всему дереву
        }
    }
}
