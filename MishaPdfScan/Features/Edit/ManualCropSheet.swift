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
                    Button("Отмена") { dismiss(); onFinish(nil) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Обрезать") {
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
    private let handleSize: CGFloat = 22
    private let edgeHit: CGFloat = 30

    @State private var baseRect: CGRect = .zero

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

            // Перемещение всей области — ПОД ручками
            Rectangle()
                .fill(.clear)
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            if baseRect == .zero { baseRect = cropRect }
                            var r = baseRect.offsetBy(dx: g.translation.width, dy: g.translation.height)
                            r = clamp(r, in: bounds, minSize: minSize)
                            cropRect = r
                        }
                        .onEnded { _ in baseRect = .zero }
                )
                .zIndex(0)

            // Угловые ручки — САМАЯ верхняя zIndex
            handle(.topLeft).zIndex(3)
            handle(.topRight).zIndex(3)
            handle(.bottomLeft).zIndex(3)
            handle(.bottomRight).zIndex(3)

            // Боковые ручки — выше рамки/сетки, ниже углов (чтобы углы «побеждали» на пересечении)
            edgeHandle(.top).zIndex(2)
            edgeHandle(.bottom).zIndex(2)
            edgeHandle(.left).zIndex(2)
            edgeHandle(.right).zIndex(2)
        }
    }

    // MARK: — Ручки
    private func handle(_ corner: Corner) -> some View {
        Circle()
            .fill(.white)
            .overlay(Circle().stroke(.black.opacity(0.6), lineWidth: 1))
            .frame(width: handleSize, height: handleSize)
            .position(cornerPos(corner))
            .contentShape(Circle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        if baseRect == .zero { baseRect = cropRect }
                        var r = resize(from: baseRect, corner: corner, t: g.translation)
                        r = clamp(r, in: bounds, minSize: minSize)
                        cropRect = r
                    }
                    .onEnded { _ in baseRect = .zero }
            )
    }

    private func edgeHandle(_ edge: Edge) -> some View {
        // Хит-зона полностью ВНУТРИ рамки
        Rectangle()
            .fill(.clear)
            .frame(width: edge.isVertical ? edgeHit : cropRect.width,
                   height: edge.isHorizontal ? edgeHit : cropRect.height)
            .position(edgeCenterInside(edge))
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        if baseRect == .zero { baseRect = cropRect }
                        var r = resize(from: baseRect, edge: edge, t: g.translation)
                        r = clamp(r, in: bounds, minSize: minSize)
                        cropRect = r
                    }
                    .onEnded { _ in baseRect = .zero }
            )
    }

    // MARK: — Геометрия позиций
    private func cornerPos(_ c: Corner) -> CGPoint {
        switch c {
        case .topLeft:     return .init(x: cropRect.minX, y: cropRect.minY)
        case .topRight:    return .init(x: cropRect.maxX, y: cropRect.minY)
        case .bottomLeft:  return .init(x: cropRect.minX, y: cropRect.maxY)
        case .bottomRight: return .init(x: cropRect.maxX, y: cropRect.maxY)
        }
    }

    // Центруем полосы ВНУТРИ прямоугольника, а не на самой границе
    private func edgeCenterInside(_ e: Edge) -> CGPoint {
        switch e {
        case .top:    return .init(x: cropRect.midX, y: cropRect.minY + edgeHit/2)
        case .bottom: return .init(x: cropRect.midX, y: cropRect.maxY - edgeHit/2)
        case .left:   return .init(x: cropRect.minX + edgeHit/2, y: cropRect.midY)
        case .right:  return .init(x: cropRect.maxX - edgeHit/2, y: cropRect.midY)
        }
    }

    // MARK: — Ресайз из базового прямоугольника
    private func resize(from base: CGRect, corner: Corner, t: CGSize) -> CGRect {
        var r = base
        switch corner {
        case .topLeft:
            r.origin.x = base.origin.x + t.width
            r.size.width  = max(minSize, base.width  - t.width)
            r.origin.y = base.origin.y + t.height
            r.size.height = max(minSize, base.height - t.height)
        case .topRight:
            r.size.width  = max(minSize, base.width  + t.width)
            r.origin.y = base.origin.y + t.height
            r.size.height = max(minSize, base.height - t.height)
        case .bottomLeft:
            r.origin.x = base.origin.x + t.width
            r.size.width  = max(minSize, base.width  - t.width)
            r.size.height = max(minSize, base.height + t.height)
        case .bottomRight:
            r.size.width  = max(minSize, base.width  + t.width)
            r.size.height = max(minSize, base.height + t.height)
        }
        return r
    }

    private func resize(from base: CGRect, edge: Edge, t: CGSize) -> CGRect {
        var r = base
        switch edge {
        case .top:
            r.origin.y = base.origin.y + t.height
            r.size.height = max(minSize, base.height - t.height)
        case .bottom:
            r.size.height = max(minSize, base.height + t.height)
        case .left:
            r.origin.x = base.origin.x + t.width
            r.size.width = max(minSize, base.width - t.width)
        case .right:
            r.size.width = max(minSize, base.width + t.width)
        }
        return r
    }

    // MARK: — Утилиты
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
    enum Edge { case top, bottom, left, right
        var isVertical: Bool   { self == .left || self == .right }
        var isHorizontal: Bool { self == .top  || self == .bottom }
    }
}
