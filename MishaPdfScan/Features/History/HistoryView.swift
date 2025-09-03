//
//  HistoryView.swift
//  MishaPdfScan
//
//  Created by mac air on 9/3/25.
//


// =====================================
// Features/History/HistoryView.swift — список всех сохранённых PDF
// =====================================
import SwiftUI


struct HistoryView: View {
    @EnvironmentObject private var history: HistoryStore
    
    
    var body: some View {
        NavigationStack {
            List {
                if history.scans.isEmpty {
                    Text("history.empty").foregroundStyle(.secondary)
                }
                ForEach(history.scans) { item in
                    NavigationLink {
                        PDFViewer(url: item.url)
                            .navigationTitle(item.name)
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack {
                            Image(systemName: "doc.richtext").font(.title3)
                            VStack(alignment: .leading) {
                                Text(item.name)
                                Text("\(formatSize(item.sizeBytes)) • \(formatDate(item.createdAt))").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            // Поделиться PDF (SwiftUI ShareLink)
                            if #available(iOS 16.0, *) {
                                ShareLink(item: item.url) { Image(systemName: "square.and.arrow.up") }
                                    .buttonStyle(.borderless)
                            }
                        }
                    }
                    .swipeActions(allowsFullSwipe: true) {
                        Button(role: .destructive) { delete(item) } label: { Label("history.delete", systemImage: "trash") }
                    }
                    .contextMenu {
                        Button(role: .destructive) { delete(item) } label: { Label("history.delete", systemImage: "trash") }
                        if #available(iOS 16.0, *) {
                            ShareLink(item: item.url) { Label("history.share", systemImage: "square.and.arrow.up") }
                        }
                    }
                }
                .onDelete { history.delete(at: $0) }
            }
            .navigationTitle("history.title")

            
            .toolbar { Button{ history.refresh() } label: { Label("history.refresh", systemImage: "arrow.clockwise") }}
        }
    }
    
    
    private func delete(_ item: ScanItem) { if let i = history.scans.firstIndex(of: item) { history.delete(at: IndexSet(integer: i)) } }
    private func formatSize(_ bytes: Int) -> String {
        let f = ByteCountFormatter(); f.allowedUnits = [.useKB, .useMB]; f.countStyle = .file
        return f.string(fromByteCount: Int64(bytes))
    }
    private func formatDate(_ d: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f.string(from: d) }
}
