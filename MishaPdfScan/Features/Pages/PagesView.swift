// =====================================
// Features/Pages/PagesView.swift
// =====================================
import SwiftUI


public struct PagesView: View {
    @EnvironmentObject private var store: PagesStore
    
    @State private var showShare = false
    @State private var showExporter = false
    @State private var pdfData: Data = Data()
    @State private var exportURL: URL?
    @State private var filename = PdfService.defaultFilename()

    
    public init() {}
    
    
    public var body: some View {
        List {
            Section("Pages") {
                ForEach(Array(store.pages.enumerated()), id: \.element.id) { idx, page in
                    NavigationLink {
                        PageEditorView(pageID: page.id, index: idx + 1, total: store.pages.count)
                            .environmentObject(store) // если не пролито сверху

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
        .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        // A) ShareLink (iOS 16+): быстро поделиться
                        if #available(iOS 16.0, *) {
                            Button {
                                let svc = PdfService()
                                let data = svc.makePDFData(images: store.pages.map(\.image))
                                filename = PdfService.defaultFilename()
                                do {
                                    let url = try svc.writePDFToCaches(data, filename: filename)
                                    exportURL = url
                                    showShare = true   // через ShareSheet (надёжнее на iOS)
                                } catch {
                                    // как fallback: покажем fileExporter
                                    pdfData = data
                                    showExporter = true
                                }
                            } label: {
                                Label("Экспорт", systemImage: "square.and.arrow.up")
                            }
                            .disabled(store.pages.isEmpty)
                        } else {
                            // < iOS 16 — сразу ShareSheet
                            Button {
                                let svc = PdfService()
                                let data = svc.makePDFData(images: store.pages.map(\.image))
                                filename = PdfService.defaultFilename()
                                do {
                                    let url = try svc.writePDFToCaches(data, filename: filename)
                                    exportURL = url
                                    showShare = true
                                } catch {
                                    // no-op
                                }
                            } label: {
                                Label("Экспорт", systemImage: "square.and.arrow.up")
                            }
                            .disabled(store.pages.isEmpty)
                        }
                    }
                }
                // B) Поделиться (UIActivityViewController)
                .sheet(isPresented: $showShare) {
                    if let url = exportURL {
                        ShareSheet(items: [url])
                    }
                }
                // C) Сохранить в «Файлы» (fileExporter)
                .fileExporter(isPresented: $showExporter,
                              document: PDFFileDocument(data: pdfData),
                              contentType: .pdf,
                              defaultFilename: filename) { result in
                    // можно обработать результат при желании
                }
    }
}
