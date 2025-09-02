
// =====================================
// Features/Edit/PageEditorView.swift
// =====================================
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

public struct PageEditorView: View {
    @EnvironmentObject private var store: PagesStore
    let pageID: UUID
    let index: Int
    let total: Int

    @State private var working: UIImage
    @State private var showCrop = false

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
    @State private var contrast: Double = 1
    @State private var saturation: Double = 1

    private let ciCtx = CIContext()

    public init(pageID: UUID, index: Int, total: Int) {
        self.pageID = pageID
        self.index = index
        self.total = total
        // temp image placeholder; real value set in .onAppear
        _working = State(initialValue: UIImage())
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                GeometryReader { geo in
                    Image(uiImage: previewImage())
                        .resizable().scaledToFit()
                        .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                        .background(Color.black)
                }
                Text("\(index) / \(total)")
                    .font(.caption).bold()
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(12)
            }
            .frame(maxHeight: .infinity)

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
            if let p = store.pages.first(where: { $0.id == pageID }) {
                working = p.image
            }
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Сброс") { resetAll() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Готово") { store.update(pageID: pageID, image: previewImage()) }.bold()
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button { if let r = working.rotated(byDegrees: -90) { working = r } } label: { Label("Повернуть", systemImage: "rotate.left") }
                    .buttonStyle(.bordered)
                Button { if let r = working.rotated(byDegrees: 90)  { working = r } } label: { Label("Повернуть", systemImage: "rotate.right") }
                    .buttonStyle(.bordered)
                Button { showCrop = true } label: { Label("Обрезать", systemImage: "crop") }
                    .buttonStyle(.bordered)
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

    private func resetAll() {
        if let p = store.pages.first(where: { $0.id == pageID }) { working = p.image }
        preset = .original
        brightness = 0
        contrast = 1
        saturation = 1
    }

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
        f.contrast = Float(contrast)
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
