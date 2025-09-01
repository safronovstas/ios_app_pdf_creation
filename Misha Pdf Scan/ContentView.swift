import SwiftUI
import PhotosUI

struct ScannedPage: Identifiable, Hashable {
    let id = UUID()
    var image: UIImage
}

struct ContentView: View {
    @StateObject private var camera = CameraController()
    @State private var showPicker = false
    @State private var pages: [ScannedPage] = []
    @State private var showingExportAlert = false
    @State private var processing = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                ZStack {
                    CameraView(controller: camera)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.2)))
                        .aspectRatio(3/4, contentMode: .fit)
                    if !camera.authorized {
                        Text("Enable camera access in Settings")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                HStack(spacing: 12) {
                    Button {
                        camera.capture()
                    } label: {
                        Label("Capture", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!camera.running)

                    Button {
                        presentPhotoPicker()
                    } label: {
                        Label("Upload", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(.bordered)
                }

                List {
                    Section("Pages") {
                        if pages.isEmpty {
                            Text("No pages yet. Capture or upload to start.")
                                .foregroundStyle(.secondary)
                        }
                        // ✅ Индексный ForEach + биндинг к элементу массива
                       ForEach(Array(pages.enumerated()), id: \.element.id) { idx, _ in
                           PageRow(
                               page: $pages[idx],
                               index: idx + 1,
                               onDelete: { pages.remove(at: idx) }
                           )
                       }
                    }
                }
                .frame(maxHeight: 220)

                Button {
                    exportPDF()
                } label: {
                    Label("Export PDF", systemImage: "doc.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(pages.isEmpty || processing)
            }
            .padding()
            .navigationTitle("NovaScan AI")
            .toolbar { ToolbarItem(placement: .principal) { Text("NovaScan AI").font(.headline) } }
        }
        .onAppear {
                    // КУДА добавляем выбранные фото
                    camera.onPickedImages = { imgs in
                        withAnimation {
                            pages.append(contentsOf: imgs.map { ScannedPage(image: $0) })
                        }
                    }
                }
        .task { await camera.start() }
        .onReceive(camera.$capturedImage.compactMap { $0 }) { img in
            processing = true
            DispatchQueue.global(qos: .userInitiated).async {
                let enhanced = ImageProcessor.autoEnhance(image: img)
                let page = ScannedPage(image: enhanced)
                DispatchQueue.main.async { pages.append(page); processing = false }
            }
        }
    }

    func presentPhotoPicker() {
        if #available(iOS 14.0, *) {
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.filter = .images              // только картинки
            config.selectionLimit = 0            // 0 = без лимита, иначе укажите число

            let picker = PHPickerViewController(configuration: config)
            picker.delegate = camera             // ваш объект-делегат (см. ниже)
            UIApplication.shared.topMostViewController()?.present(picker, animated: true)
        } else {
            // iOS < 14: мультивыбора нет, можно оставить старый UIImagePickerController (один файл)
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.allowsEditing = false
            picker.delegate = camera
            UIApplication.shared.topMostViewController()?.present(picker, animated: true)
        }
    }

    func exportPDF() {
        guard !pages.isEmpty else { return }
        let images = pages.map { $0.image }
        let url = PDFExporter.export(images: images, filename: "scan.pdf")
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.topMostViewController()?.present(activity, animated: true)
    }
}

private extension UIApplication {
    func topMostViewController(_ base: UIViewController? = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController { return topMostViewController(nav.visibleViewController) }
        if let tab = base as? UITabBarController { return topMostViewController(tab.selectedViewController) }
        if let presented = base?.presentedViewController { return topMostViewController(presented) }
        return base
    }
}
