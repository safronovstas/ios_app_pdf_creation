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
    @State private var selection: [PhotosPickerItem] = []
    @State private var showCamera = false
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                PhotosPicker(selection: $selection, maxSelectionCount: 50, matching: .images) {
                    Label("Выбрать из галереи", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity)
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
                    Label("Сканировать", systemImage: "camera.viewfinder").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                
                if store.pages.isEmpty {
                    Spacer(); Text("Начни со сканирования или импорта из галереи").foregroundStyle(.secondary); Spacer()
                } else {
                    PagesView() // ваш экран списка с редактором и экспортом
                }
            }
            .padding()
            .navigationTitle("Home")
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraScreen { captured in if let captured { store.add(images: [captured]) } }
        }
    }
}
