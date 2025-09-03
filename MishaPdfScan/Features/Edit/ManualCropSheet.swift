import SwiftUI

struct ManualCropSheet: View {
    let image: UIImage
    let onFinish: (UIImage?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cropRect: CGRect = .zero         // в координатах экрана
    @State private var imageFrame: CGRect = .zero       // где реально лежит картинка
    private var isReady: Bool { imageFrame.width > 0 && imageFrame.height > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                GeometryReader { geo in
                    ZStack {
                        // Картинка по центру, FIT
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(image.size, contentMode: .fit)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .background(Color.clear)

                        // Показ UI только когда известен imageFrame
                        if isReady {
                            // Тень вокруг
                            Color.black.opacity(0.55)
                                .mask(CropMask(cropRect: cropRect).fill(style: FillStyle(eoFill: true)))
                                .allowsHitTesting(false)              // ← не перехватывать тапы
                            
                            // Сетка + ручки + перетаскивание
                            CropOverlay(cropRect: $cropRect, bounds: imageFrame)
                        }
                    }
                    .contentShape(Rectangle())
                    // ВАЖНО: вычисляем imageFrame и стартовый cropRect
                    .onAppear { updateFrames(container: geo.size) }
                    .onChange(of: geo.size) { newSize in updateFrames(container: newSize) }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss(); onFinish(nil) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("editor.crop") {
                        onFinish(renderCropped())
                        dismiss()
                    }.bold().disabled(!isReady)
                }
            }
        }
    }

    private func updateFrames(container: CGSize) {
        // куда впишется изображение (без учёта safe area уже, т.к. сверху ZStack игнорит её)
        let fitted = fittedSize(content: image.size, into: container)
        let frame = CGRect(
            x: (container.width  - fitted.width)  / 2,
            y: (container.height - fitted.height) / 2,
            width: fitted.width,
            height: fitted.height
        )

        imageFrame = frame

        // инициализируем cropRect один раз или подгоняем, если экран повернулся
        if cropRect == .zero {
            cropRect = frame.insetBy(dx: frame.width * 0.1, dy: frame.height * 0.1)
        } else {
            // гарантируем, что рамка внутри изображения
            cropRect = clamp(cropRect, in: frame)
        }
    }

    private func fittedSize(content: CGSize, into container: CGSize) -> CGSize {
        let scale = min(container.width  / max(content.width, 1),
                        container.height / max(content.height, 1))
        return CGSize(width: content.width * scale, height: content.height * scale)
    }

    private func renderCropped() -> UIImage? {
        guard isReady else { return nil }

        // Перевод экранных координат в пиксели исходника
        let sx = image.size.width  / imageFrame.width
        let sy = image.size.height / imageFrame.height

        let x = max(0, (cropRect.minX - imageFrame.minX) * sx)
        let y = max(0, (cropRect.minY - imageFrame.minY) * sy)
        let w = max(1, cropRect.width  * sx)
        let h = max(1, cropRect.height * sy)

        let rect = CGRect(x: floor(x), y: floor(y), width: floor(w), height: floor(h))
        return image.cropped(to: rect)
    }
    

    private func clamp(_ rect: CGRect, in bounds: CGRect, minSize: CGFloat = 40) -> CGRect {
        // если рамки изображения ещё не посчитаны — не ограничиваем
        guard bounds.width > 0 && bounds.height > 0 else { return rect }

        var r = rect
        r.size.width  = max(r.width,  minSize)
        r.size.height = max(r.height, minSize)
        if r.minX < bounds.minX { r.origin.x = bounds.minX }
        if r.minY < bounds.minY { r.origin.y = bounds.minY }
        if r.maxX > bounds.maxX { r.origin.x = bounds.maxX - r.width }
        if r.maxY > bounds.maxY { r.origin.y = bounds.maxY - r.height }
        return r
    }

}

#if DEBUG
struct ManualCropSheet_Previews: PreviewProvider {
    static var previews: some View {
        ManualCropSheet(image: PreviewHelpers.placeholderImage(), onFinish: { _ in })
    }
}
#endif

struct CropMask: Shape {
    var cropRect: CGRect
    func path(in rect: CGRect) -> Path {
        var p = Path(rect)
        p.addRect(cropRect)
        return p
    }
}

private struct CropOverlay: View {
    @Binding var cropRect: CGRect
    let bounds: CGRect

    private let minSize: CGFloat = 40
    private let handleSize: CGFloat = 28
    private let hitExpand: CGFloat = 12   // расширение хит-зоны

    @State private var baseRect: CGRect = .zero
    @State private var active: Corner? = nil

    var body: some View {
        ZStack {
            // Рамка
            Path { $0.addRect(cropRect) }
                .strokedPath(.init(lineWidth: 2, dash: [6, 4]))
                .foregroundStyle(.white)
                .zIndex(1)

            // Сетка 3×3
            ForEach(1..<3) { i in
                Path { p in
                    let x = cropRect.minX + CGFloat(i) * cropRect.width / 3
                    p.move(to: CGPoint(x: x, y: cropRect.minY))
                    p.addLine(to: CGPoint(x: x, y: cropRect.maxY))
                }.stroke(.white.opacity(0.6), lineWidth: 1)
                Path { p in
                    let y = cropRect.minY + CGFloat(i) * cropRect.height / 3
                    p.move(to: CGPoint(x: cropRect.minX, y: y))
                    p.addLine(to: CGPoint(x: cropRect.maxX, y: y))
                }.stroke(.white.opacity(0.6), lineWidth: 1)
            }
            .zIndex(1)

            // УГЛЫ — единственный способ менять рамку
            cornerHandle(.topLeft).zIndex(3)
            cornerHandle(.topRight).zIndex(3)
            cornerHandle(.bottomLeft).zIndex(3)
            cornerHandle(.bottomRight).zIndex(3)
        }
    }

    // MARK: — Угловая ручка
    private func cornerHandle(_ c: Corner) -> some View {
        // большая невидимая хит-зона + видимая «кнопка»
        ZStack {
            // хит-зона ~44pt, чтобы легко схватить
            Rectangle().fill(Color.clear)
                .frame(width: 44, height: 44)

            Circle()
                .fill(active == c ? Color.yellow : Color.white)
                .overlay(Circle().stroke(.black.opacity(0.6), lineWidth: 1))
                .frame(width: 28, height: 28)
        }
        .position(cornerPos(c))
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    if baseRect == .zero {
                        baseRect = cropRect
                        active = c
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    var r = resize(from: baseRect, corner: c, t: g.translation)
                    r = clamp(r, in: bounds, minSize: 40)
                    cropRect = r
                }
                .onEnded { _ in
                    baseRect = .zero
                    active = nil
                }
        )
    }


    // MARK: — Геометрия углов
    private func cornerPos(_ c: Corner) -> CGPoint {
        switch c {
        case .topLeft:     return .init(x: cropRect.minX, y: cropRect.minY)
        case .topRight:    return .init(x: cropRect.maxX, y: cropRect.minY)
        case .bottomLeft:  return .init(x: cropRect.minX, y: cropRect.maxY)
        case .bottomRight: return .init(x: cropRect.maxX, y: cropRect.maxY)
        }
    }

    // MARK: — Ресайз от базового прямоугольника
    private func resize(from base: CGRect, corner: Corner, t: CGSize) -> CGRect {
        var r = base
        switch corner {
        case .topLeft:
            r.origin.x    = base.origin.x + t.width
            r.size.width  = max(minSize, base.width  - t.width)
            r.origin.y    = base.origin.y + t.height
            r.size.height = max(minSize, base.height - t.height)
        case .topRight:
            r.size.width  = max(minSize, base.width  + t.width)
            r.origin.y    = base.origin.y + t.height
            r.size.height = max(minSize, base.height - t.height)
        case .bottomLeft:
            r.origin.x    = base.origin.x + t.width
            r.size.width  = max(minSize, base.width  - t.width)
            r.size.height = max(minSize, base.height + t.height)
        case .bottomRight:
            r.size.width  = max(minSize, base.width  + t.width)
            r.size.height = max(minSize, base.height + t.height)
        }
        return r
    }

    // MARK: — Ограничение в пределах изображения
    private func clamp(_ rect: CGRect, in bounds: CGRect, minSize: CGFloat) -> CGRect {
        guard bounds.width > 0, bounds.height > 0 else { return rect }
        var r = rect
        r.size.width  = max(r.width,  minSize)
        r.size.height = max(r.height, minSize)
        if r.minX < bounds.minX { r.origin.x = bounds.minX }
        if r.minY < bounds.minY { r.origin.y = bounds.minY }
        if r.maxX > bounds.maxX { r.origin.x = bounds.maxX - r.width }
        if r.maxY > bounds.maxY { r.origin.y = bounds.maxY - r.height }
        return r
    }

    enum Corner { case topLeft, topRight, bottomLeft, bottomRight }
}
