//
//  HomeView.swift
//  MishaPdfScan
//
//  Created by mac air on 9/3/25.
//


// =====================================
// Features/Home/HomeView.swift — ваш текущий поток (галерея/камера → Pages)
// =====================================
import SwiftUI
import PhotosUI


struct HomeView: View {
    @EnvironmentObject private var store: PagesStore
    @EnvironmentObject private var history: HistoryStore
    @State private var selection: [PhotosPickerItem] = []
    @State private var showCamera = false
    // Export state
    @State private var savedURL: URL?
    @State private var showSavedAlert = false
    @State private var showShare = false
    @State private var exportError: String?
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                PhotosPicker(selection: $selection, maxSelectionCount: 50, matching: .images) {
                    Label("home.pick_from_gallery", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .onChange(of: selection) { newItems in
                    Task {
                        var imgs: [UIImage] = []
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) { imgs.append(img) }
                        }
                        await MainActor.run { store.add(images: imgs) }
                        selection.removeAll()
                    }
                }
                
                
                Button { showCamera = true } label: {
                    Label("home.scan", systemImage: "camera.viewfinder").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                
                if store.pages.isEmpty {
                    Spacer(); Text("home.empty_message").foregroundStyle(.secondary); Spacer()
                } else {
                    PagesView() // ваш экран списка с редактором и экспортом
                }
            }
            .padding()
            .navigationTitle("home.title")
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraScreen { captured in if let captured { store.add(images: [captured]) } }
        }
        // Кнопка завершения добавления страниц (сохранить в Историю)
        .safeAreaInset(edge: .bottom) {
            if !store.pages.isEmpty {
                HStack {
                    Button {
                        Task {
                            do {
                                let svc = PdfService()
                                let data = svc.makePDFData(images: store.pages.map(\.image), options: .default)
                                let filename = PdfService.defaultFilename()
                                let url = try svc.writePDFToDocuments(data, filename: filename)
                                history.add(url: url)
                                await MainActor.run {
                                    savedURL = url
                                    store.clear()
                                    showSavedAlert = true
                                }
                            } catch {
                                await MainActor.run { exportError = error.localizedDescription }
                            }
                        }
                    } label: {
                        Label("home.done_button", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.horizontal).padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
        }
        // Сообщение об успешном сохранении с предложением поделиться
        .alert("alert.saved.title", isPresented: $showSavedAlert) {
            Button("alert.saved.share") { showShare = true }
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("alert.saved.message")
        }
        // Ошибка экспорта
        .alert("alert.export_error.title", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } })
        ) { Button("common.ok", role: .cancel) {} } message: { Text(exportError ?? "") }
        // Шеринг PDF
        .sheet(isPresented: $showShare) {
            if let url = savedURL { ShareSheet(items: [url]) }
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
                .environmentObject(PagesStore.preview(withPages: 3))
                .environmentObject(HistoryStore.previewWithSamples(count: 2))
        }
    }
}
#endif
