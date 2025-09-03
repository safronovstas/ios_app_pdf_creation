// Features/Edit/PageEditorView.swift
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

public struct PageEditorView: View {
    @EnvironmentObject private var store: PagesStore
    
    // Вход из списка
    let pageID: UUID
    let startIndex: Int   // 1-based из списка
    
    @Environment(\.dismiss) private var dismiss

    
    // Текущее состояние
    @State private var currentIndex: Int = 0 // 0-based
    @State private var working: UIImage = UIImage()
    @State private var showCrop = false
    
    // Жест/анимация
    @State private var dragX: CGFloat = 0
    
    // Цветокоррекция
    enum ColorPreset: String, CaseIterable, Identifiable { case original, enhance, mono, document
        public var id: String { rawValue }
        var title: String {
            switch self {
            case .original: return "Оригинал"
            case .enhance:  return "Улучшение"
            case .mono:     return "Ч/Б"
            case .document: return "Документ"
            }
        }
    }
    @State private var preset: ColorPreset = .original
    @State private var brightness: Double = 0
    @State private var contrast:   Double = 1
    @State private var saturation: Double = 1
    
    private let ciCtx = CIContext()
    
    public init(pageID: UUID, index: Int, total: Int) {
        self.pageID = pageID
        self.startIndex = max(1, index)
        // total не нужен — возьмём из store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                
                GeometryReader { geo in
                    let w = max(1, geo.size.width)
                    let total = store.pages.count
                    let hasPrev = currentIndex > 0
                    let hasNext = currentIndex < total - 1
                    
                    ZStack {
                        // PREV (слева, параллакс)
                        if hasPrev, let prev = store.pages[currentIndex - 1].image as UIImage? {
                            Image(uiImage: prev)
                                .resizable().scaledToFit()
                                .offset(x: -w + dragX * 0.3)                      // параллакс
                                .scaleEffect(0.94)                                 // глубина
                                .opacity(0.7)
                        }
                        
                        // CURRENT (по центру, 3D наклон)
                        Image(uiImage: previewImage())
                            .resizable()
                            .scaledToFit()
                            .offset(x: dragX)
                            .rotation3DEffect(.degrees(Double(-8 * (dragX / w))),  // лёгкий наклон
                                              axis: (x: 0, y: 1, z: 0),
                                              perspective: 0.6)
                            .shadow(radius: abs(dragX) / 40)
                        
                        // NEXT (справа, параллакс)
                        if hasNext, let next = store.pages[currentIndex + 1].image as UIImage? {
                            Image(uiImage: next)
                                .resizable().scaledToFit()
                                .offset(x: w + dragX * 0.3)
                                .scaleEffect(0.94)
                                .opacity(0.7)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .center) // центрируем всю группу
                    .contentShape(Rectangle())
                    .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.85), value: dragX)
                    .gesture(
                        DragGesture(minimumDistance: 12, coordinateSpace: .local)
                            .onChanged { g in
                                // резинка на краях
                                var x = g.translation.width
                                if (x > 0 && !hasPrev) || (x < 0 && !hasNext) { x *= 0.35 }
                                dragX = x
                            }
                            .onEnded { g in
                                let predicted = g.predictedEndTranslation.width
                                let threshold = w * 0.28
                                
                                func commit(_ delta: Int) {
                                    // хаптика
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    applyEditsToCurrent()
                                    currentIndex += delta
                                    loadWorkingFromCurrent()
                                }
                                
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                    if predicted < -threshold, hasNext {
                                        commit(+1)
                                    } else if predicted > threshold, hasPrev {
                                        commit(-1)
                                    }
                                    dragX = 0
                                }
                            }
                    )
                }
                
                
                // Индикатор "i / N"
                Text("\(currentIndex + 1) / \(store.pages.count)")
                    .font(.caption).bold()
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(12)
            }
            .frame(maxHeight: .infinity)
            
            // Панель инструментов внизу
            controls
                .padding(.top, 8)
                .background(.ultraThinMaterial)
        }
        .navigationTitle("Редактирование")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .sheet(isPresented: $showCrop) {
            ManualCropSheet(image: working) { cropped in
                if let cropped { working = cropped }
            }
        }
        .onAppear {
            // установить стартовый индекс (если массив менялся, перепроверим по id)
            if let idxByID = store.pages.firstIndex(where: { $0.id == pageID }) {
                currentIndex = idxByID
            } else {
                currentIndex = max(0, min(store.pages.count - 1, startIndex - 1))
            }
            loadWorkingFromCurrent()
        }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Сброс") { resetAll() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Готово") {
                applyEditsToCurrent()     // сохранить изменения текущей страницы
                dismiss()                  // ← вернуться на список
            }.bold()
        }
    }
    
    // MARK: - Bottom controls
    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button { if let r = working.rotated(byDegrees: -90) { working = r } } label: {
                    Label("Повернуть", systemImage: "rotate.left")
                }.buttonStyle(.bordered)
                
                Button { if let r = working.rotated(byDegrees: 90) { working = r } } label: {
                    Label("Повернуть", systemImage: "rotate.right")
                }.buttonStyle(.bordered)
                
                Button { showCrop = true } label: {
                    Label("Обрезать", systemImage: "crop")
                }.buttonStyle(.bordered)
                
                Spacer()
            }
            
            Picker("Режим", selection: $preset) {
                ForEach(ColorPreset.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack { Text("Яркость"); Spacer(); Text(String(format: "%.2f", brightness)) }
                Slider(value: $brightness, in: -1...1)
                HStack { Text("Контраст"); Spacer(); Text(String(format: "%.2f", contrast)) }
                Slider(value: $contrast, in: 0...4)
                HStack { Text("Насыщенность"); Spacer(); Text(String(format: "%.2f", saturation)) }
                Slider(value: $saturation, in: 0...2)
            }
            .font(.caption)
        }
        .padding([.horizontal, .bottom])
    }
    
    // MARK: - Helpers
    private func resetAll() {
        if let p = safePage(at: currentIndex) { working = p.image }
        preset = .original
        brightness = 0; contrast = 1; saturation = 1
    }
    
    private func applyEditsToCurrent() {
        guard let p = safePage(at: currentIndex) else { return }
        store.update(pageID: p.id, image: previewImage())
    }
    
    private func loadWorkingFromCurrent() {
        if let p = safePage(at: currentIndex) { working = p.image; resetColorControls() }
    }
    
    private func resetColorControls() {
        preset = .original
        brightness = 0; contrast = 1; saturation = 1
    }
    
    private func safePage(at idx: Int) -> Page? {
        guard idx >= 0 && idx < store.pages.count else { return nil }
        return store.pages[idx]
    }
    
    // Рендер пайплайн
    private func previewImage() -> UIImage {
        var img = working
        img = applyPreset(img)
        img = applyAdjust(img, brightness: brightness, contrast: contrast, saturation: saturation)
        return img
    }
    
    private func applyPreset(_ image: UIImage) -> UIImage {
        switch preset {
        case .original: return image
        case .enhance:
            let a = applyAdjust(image, brightness: 0, contrast: 1.15, saturation: 1.1)
            return sharpen(a, amount: 0.4)
        case .mono:
            return noir(image)
        case .document:
            let bw = applyAdjust(image, brightness: 0.02, contrast: 1.35, saturation: 0)
            return sharpen(bw, amount: 0.6)
        }
    }
    
    private func applyAdjust(_ image: UIImage, brightness: Double, contrast: Double, saturation: Double) -> UIImage {
        guard let cg = image.cgImage else { return image }
        let ci = CIImage(cgImage: cg)
        let f = CIFilter.colorControls()
        f.inputImage = ci
        f.brightness = Float(brightness)
        f.contrast   = Float(contrast)
        f.saturation = Float(saturation)
        return render(filter: f, fallback: image)
    }
    
    private func noir(_ image: UIImage) -> UIImage {
        guard let cg = image.cgImage else { return image }
        let ci = CIImage(cgImage: cg)
        let f = CIFilter.photoEffectNoir()
        f.inputImage = ci
        return render(filter: f, fallback: image)
    }
    
    private func sharpen(_ image: UIImage, amount: Double) -> UIImage {
        guard let cg = image.cgImage else { return image }
        let ci = CIImage(cgImage: cg)
        let f = CIFilter.sharpenLuminance()
        f.inputImage = ci
        f.sharpness = Float(amount)
        return render(filter: f, fallback: image)
    }
    
    private func render(filter: CIFilter, fallback: UIImage) -> UIImage {
        guard let out = filter.outputImage,
              let cg = ciCtx.createCGImage(out, from: out.extent) else { return fallback }
        return UIImage(cgImage: cg, scale: fallback.scale, orientation: fallback.imageOrientation)
    }
}
