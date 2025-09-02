// =====================================
// Features/Pages/PagesView.swift
// =====================================
import SwiftUI


public struct PagesView: View {
    @EnvironmentObject private var store: PagesStore
    
    
    public init() {}
    
    
    public var body: some View {
        List {
            Section("Pages") {
                ForEach(Array(store.pages.enumerated()), id: \.element.id) { idx, page in
                    NavigationLink {
                        PageEditorView(pageID: page.id, index: idx + 1, total: store.pages.count)
                    } label: {
                        HStack {
                            Image(uiImage: page.image)
                                .resizable().scaledToFill()
                                .frame(width: 64, height: 96).clipped().cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                            Text("Page \(idx + 1)")
                            Spacer()
                            Button { store.rotate(pageID: page.id, degrees: -90) } label: { Image(systemName: "rotate.left") }
                                .buttonStyle(.plain)
                            Button { store.rotate(pageID: page.id, degrees: 90) } label: { Image(systemName: "rotate.right") }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .onDelete(perform: store.remove)
            }
        }
    }
}
