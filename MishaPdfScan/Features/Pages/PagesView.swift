import SwiftUI
import UniformTypeIdentifiers

public struct PagesView: View {
    @EnvironmentObject private var store: PagesStore

    // экспорт
    @State private var showOptions = false
    @State private var options = PdfExportOptions.default
    @State private var showShare = false
    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var filename = PdfService.defaultFilename()

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
        .navigationTitle("Документы")
        // КНОПКА ЭКСПОРТА ВНИЗУ
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    showOptions = true
                } label: {
                    Label("Экспорт", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(store.pages.isEmpty)
            }
            .padding(.horizontal).padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        // Окно настроек экспорта
        .sheet(isPresented: $showOptions) {
            ExportOptionsSheet(options: $options) {
                Task {
                    do {
                        let svc = PdfService()
                        let data = svc.makePDFData(images: store.pages.map(\.image), options: options)
                        filename = PdfService.defaultFilename()
                        let url = try svc.writePDFToCaches(data, filename: filename)
                        exportURL = url
                        showShare = true
                    } catch {
                        exportError = error.localizedDescription
                    }
                }
            }
        }
        // Шеринг готового PDF
        .sheet(isPresented: $showShare) {
            if let url = exportURL { ShareSheet(items: [url]) }
        }
        .alert("Ошибка экспорта", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } })
        ) { Button("OK", role: .cancel) {} } message: { Text(exportError ?? "") }
    }
}
