import SwiftUI
import PhotosUI

struct ScannedPage: Identifiable, Hashable {
    let id = UUID()
    var image: UIImage
}


struct StartView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

    private let onboardingPages: [OnboardingPage] = [
        .init(title: "Сканируй документы",
              subtitle: "Используй камеру, автообрезку и выравнивание.",
              systemImage: "camera.viewfinder"),
        .init(title: "Импортируй из галереи",
              subtitle: "Выбирай сразу несколько страниц из Фото.",
              systemImage: "photo.on.rectangle"),
        .init(title: "Редактируй и экспортируй",
              subtitle: "Поворот, обрезка, PDF одним тапом.",
              systemImage: "doc.richtext")
    ]
    
    
    // ДОЛЖЕН жить долго: делегат камеры/пикера
    @StateObject private var camera = CameraController()

    // Твои страницы. Если у тебя есть PagesStore — замени на @EnvironmentObject.
    @State private var pages: [ScannedPage] = []

    @State private var showGallery = false
    @State private var showCamera  = false
    @State private var processing = false


    func exportPDF() {
        guard !pages.isEmpty else { return }
        let images = pages.map { $0.image }
        let url = PDFExporter.export(images: images, filename: "scan.pdf")
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.topMostViewController()?.present(activity, animated: true)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // КНОПКА: Сканировать (камера)
                Button {
                    showCamera = true
                } label: {
                    Label("Сканировать", systemImage: "camera.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                // КНОПКА: Выбрать из галереи (мультивыбор)
                Button {
                    showGallery = true
                } label: {
                    Label("Выбрать из галереи", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                // (опционально) снизу краткий список выбранных страниц
                if !pages.isEmpty {
                    List {
                        Section("Страницы") {
                            ForEach(Array(pages.enumerated()), id: \.element.id) { idx, _ in
                                PageRow(
                                    page: $pages[idx],
                                    index: idx + 1,
                                    onDelete: { pages.remove(at: idx) }
                                )
                            }
                        }
                    }
                    
                    Button {
                        exportPDF()
                    } label: {
                        Label("Export PDF", systemImage: "doc.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(pages.isEmpty || processing)
                    
                } else {
                    Spacer()
                    Text("Начни со сканирования или импорта из галереи")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Документы")
        }
        // Открыть мультивыбор Фото
        .sheet(isPresented: $showGallery) {
            PhotoPickerSheet(controller: camera) // см. блок 2
        }
        // Открыть камеру (full screen)
        .fullScreenCover(isPresented: $showCamera) {
            CameraScreen(camera: camera)        // см. блок 3
        }
        // Получаем выбранные из галереи изображения
        .onAppear {
            if !hasSeenOnboarding { showOnboarding = true }
            camera.onPickedImages = { imgs in
                withAnimation {
                    pages.append(contentsOf: imgs.map { ScannedPage(image: $0) })
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
              OnboardingView(pages: onboardingPages) {
                  hasSeenOnboarding = true
                  showOnboarding = false
              }
        }
        // Получаем кадр из камеры
        .onChange(of: camera.capturedImage) { img in
            guard let img else { return }
            withAnimation { pages.append(ScannedPage(image: img)) }
            // Если хочешь сразу закрывать камеру после кадра:
            showCamera = false
            // camera.capturedImage = nil // если нужно сбрасывать
        }
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
