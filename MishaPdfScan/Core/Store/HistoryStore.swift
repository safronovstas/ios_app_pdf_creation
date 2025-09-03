//
//  HistoryStore.swift
//  MishaPdfScan
//
//  Created by mac air on 9/3/25.
//


// =====================================
// Core/Store/HistoryStore.swift
// =====================================
import SwiftUI

@MainActor
public final class HistoryStore: ObservableObject {
    @Published public private(set) var scans: [ScanItem] = []
    private let fm = FileManager.default
    
    public init() { refresh() }   // теперь ок, init тоже на MainActor
    
    public var directory: URL {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("Scans", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) { try? fm.createDirectory(at: dir, withIntermediateDirectories: true) }
        return dir
    }
    
    
    public func refresh() {
        let dir = directory
        let urls = (try? fm.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        let items: [ScanItem] = urls.compactMap { url in
            let rv = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
            return ScanItem(url: url,
                            name: url.lastPathComponent,
                            sizeBytes: rv?.fileSize ?? 0,
                            createdAt: rv?.creationDate ?? Date())
        }
        scans = items.sorted { $0.createdAt > $1.createdAt }
    }
    
    
    public func add(url: URL)     { refresh() }
    public func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { scans[$0] }
        for item in toDelete { try? fm.removeItem(at: item.url) }
        refresh()
    }
}
