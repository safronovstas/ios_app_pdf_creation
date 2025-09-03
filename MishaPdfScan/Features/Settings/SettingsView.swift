//
//  SettingsView.swift
//  MishaPdfScan
//
//  Created by mac air on 9/3/25.
//


// =====================================
// Features/Settings/SettingsView.swift
// =====================================
import SwiftUI


struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if #available(iOS 16.0, *) {
                        ShareLink(item: URL(string: "https://example.com/app")!) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button { openURL(URL(string: "https://example.com/app")!) } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                    
                    Button {
                        if let url = URL(string: "mailto:support@example.com?subject=Scanner%20Feedback") { openURL(url) }
                    } label: { Label("Feedback", systemImage: "envelope") }
                    
                    
                    NavigationLink { TermsView() } label: { Label("Terms of Usage", systemImage: "doc.text") }
                }
                
                
                Section("About") {
                    HStack { Text("Version"); Spacer(); Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-").foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Settings")
        }
    }
}


struct TermsView: View {
    var body: some View {
        ScrollView { Text(sample).padding() }.navigationTitle("Terms of Usage").navigationBarTitleDisplayMode(.inline)
    }
    private let sample = """
These Terms of Usage are a placeholder. Put your actual terms here or load them from a remote source.
1. Use at your own risk.\n2. We do not collect personal data.\n3. ...
"""
}
