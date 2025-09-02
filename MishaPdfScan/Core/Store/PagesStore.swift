// =====================================
// Core/Store/PagesStore.swift
// =====================================
import SwiftUI


public final class PagesStore: ObservableObject {
    @Published public private(set) var pages: [Page] = []
    public init() {}
    
    
    @MainActor public func add(images: [UIImage]) {
        withAnimation { pages.append(contentsOf: images.map { Page(image: $0) }) }
    }
    
    
    @MainActor public func remove(at offsets: IndexSet) {
        withAnimation { pages.remove(atOffsets: offsets) }
    }
    
    
    @MainActor public func rotate(pageID: UUID, degrees: CGFloat) {
        guard let idx = pages.firstIndex(where: { $0.id == pageID }),
              let r = pages[idx].image.rotated(byDegrees: degrees) else { return }
        pages[idx].image = r
    }
    
    
    @MainActor public func update(pageID: UUID, image: UIImage) {
        guard let idx = pages.firstIndex(where: { $0.id == pageID }) else { return }
        pages[idx].image = image
    }
}
