//
//  ImageEditorView.swift
//  Misha Pdf Scan
//
//  Created by mac air on 9/1/25.
//

// SwiftUI Scan Editor — Rotate & Crop
// Features: Rotate 90°, Manual Crop UI (resizable/movable), optional Auto-Detect document edges via Vision
// Works with iOS 16+
// If you prefer a polished UIKit crop UI, you can swap `ManualCropSheet` with TOCropViewController via SPM.

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import Vision

// MARK: - Public API

// Use ImageEditorView in your app, pass in a starting UIImage and a completion handler that receives the edited image
struct ImageEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let original: UIImage
    let onDone: (UIImage) -> Void

    @State private var working: UIImage
    @State private var showCrop = false
    @State private var showAutoCropError = false

    init(original: UIImage, onDone: @escaping (UIImage) -> Void) {
        self.original = original
        self.onDone = onDone
        _working = State(initialValue: original)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Preview
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: working)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                        .background(Color.black)
                        .clipped()
                }
            }

            // Toolbar
            HStack(spacing: 12) {
                Button(action: rotate90) {
                    Label("Повернуть", systemImage: "rotate.right")
                }
                .buttonStyle(.bordered)

                Button(action: { showCrop = true }) {
                    Label("Обрезать", systemImage: "crop")
                }
                .buttonStyle(.bordered)

                Button(action: autoCrop) {
                    Label("Авто", systemImage: "wand.and.stars")
                }
                .buttonStyle(.bordered)
                .help("Автообрезка документа через Vision")

                Spacer()

                Button("Готово") {
                    onDone(working)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showCrop) {
            ManualCropSheet(image: working) { cropped in
                if let cropped { working = cropped }
            }
        }
        .alert("Не удалось найти границы документа", isPresented: $showAutoCropError) { Button("OK", role: .cancel) {} }
    }

    private func rotate90() {
        if let rotated = working.rotated(byDegrees: 90) { working = rotated }
    }

    private func autoCrop() {
        VisionAutoCropper.detectAndCorrectPerspective(image: working) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(img): working = img
                case .failure: showAutoCropError = true
                }
            }
        }
    }
}

// MARK: - Manual Crop Sheet (SwiftUI)

// A simple, resizable crop overlay with draggable handles. Fixed output is the selected rect mapped into the image space.
struct ManualCropSheet: View {
    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    let onFinish: (UIImage?) -> Void

    @State private var cropRect: CGRect = .zero // in view coordinates
    @State private var imageFrame: CGRect = .zero // where the image actually sits in the view

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                GeometryReader { geo in
                    ZStack {
                        // Image centered and fitted
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .background(GeometryReader { _ in
                                Color.clear.onAppear {
                                    // compute image frame after layout
                                    let fitted = ImageFitter.fittedRect(contentSize: image.size, in: geo.size)
                                    imageFrame = CGRect(origin: CGPoint(x: (geo.size.width - fitted.width) / 2,
                                                                        y: (geo.size.height - fitted.height) / 2),
                                                        size: fitted)
                                    if cropRect == .zero {
                                        // initialize crop rect with 80% of image frame
                                        let insetX = fitted.width * 0.1
                                        let insetY = fitted.height * 0.1
                                        cropRect = imageFrame.insetBy(dx: insetX, dy: insetY)
                                    }
                                }
                                .onChange(of: geo.size) { _ in
                                    let fitted = ImageFitter.fittedRect(contentSize: image.size, in: geo.size)
                                    imageFrame = CGRect(origin: CGPoint(x: (geo.size.width - fitted.width) / 2,
                                                                        y: (geo.size.height - fitted.height) / 2),
                                                        size: fitted)
                                }
                            })
                            .frame(width: geo.size.width, height: geo.size.height)

                        // Dark overlay outside crop rect
                        Color.black.opacity(0.5)
                            .mask(
                                CropMask(cropRect: cropRect)
                                    .fill(style: FillStyle(eoFill: true)),
                            )

                        // Crop rect with handles
                        CropOverlay(cropRect: $cropRect, bounds: imageFrame)
                    }
                }
            }
            .toolbar { toolbar }
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Отмена") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Обрезать") {
                let cropped = renderCropped()
                onFinish(cropped)
                dismiss()
            }
            .bold()
        }
    }

    private func renderCropped() -> UIImage? {
        // Map view cropRect -> image pixel rect
        guard imageFrame.width > 0, imageFrame.height > 0 else { return nil }
        let scaleX = image.size.width / imageFrame.width
        let scaleY = image.size.height / imageFrame.height

        let x = max(0, (cropRect.minX - imageFrame.minX) * scaleX)
        let yInView = (cropRect.minY - imageFrame.minY) * scaleY
        let h = max(1, cropRect.height * scaleY)
        let y = max(0, yInView)
        let w = max(1, cropRect.width * scaleX)

        let rect = CGRect(x: x.rounded(.down), y: y.rounded(.down), width: w.rounded(.down), height: h.rounded(.down))
        return image.cropped(to: rect)
    }
}

// MARK: - Crop Overlay + Handles

struct CropOverlay: View {
    @Binding var cropRect: CGRect
    let bounds: CGRect

    @State private var lastDrag: CGRect = .zero

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Border + grid
            Rectangle()
                .path(in: cropRect)
                .strokedPath(.init(lineWidth: 2, dash: [6, 4]))
                .foregroundStyle(.white)

            // Grid (rule of thirds)
            ForEach(1 ..< 3) { i in
                Path { p in
                    let x = cropRect.minX + CGFloat(i) * cropRect.width / 3
                    p.move(to: CGPoint(x: x, y: cropRect.minY))
                    p.addLine(to: CGPoint(x: x, y: cropRect.maxY))
                }
                .stroke(.white.opacity(0.6), lineWidth: 1)

                Path { p in
                    let y = cropRect.minY + CGFloat(i) * cropRect.height / 3
                    p.move(to: CGPoint(x: cropRect.minX, y: y))
                    p.addLine(to: CGPoint(x: cropRect.maxX, y: y))
                }
                .stroke(.white.opacity(0.6), lineWidth: 1)
            }

            // Move gesture (drag inside)
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { g in
                            if lastDrag == .zero { lastDrag = cropRect }
                            var newRect = lastDrag.offsetBy(dx: g.translation.width, dy: g.translation.height)
                            newRect = CropMath.clamp(newRect, in: bounds)
                            cropRect = newRect
                        }
                        .onEnded { _ in lastDrag = .zero },
                )
        }
        // Handles at corners & edges
        .overlay(alignment: .topLeading) { handle(.topLeft) }
        .overlay(alignment: .topTrailing) { handle(.topRight) }
        .overlay(alignment: .bottomLeading) { handle(.bottomLeft) }
        .overlay(alignment: .bottomTrailing) { handle(.bottomRight) }
        .overlay(alignment: .top) { edgeHandle(.top) }
        .overlay(alignment: .bottom) { edgeHandle(.bottom) }
        .overlay(alignment: .leading) { edgeHandle(.left) }
        .overlay(alignment: .trailing) { edgeHandle(.right) }
    }

    private func handle(_ corner: Corner) -> some View {
        Circle()
            .fill(.white)
            .frame(width: 22, height: 22)
            .overlay(Circle().stroke(.black.opacity(0.6), lineWidth: 1))
            .padding(6)
            .gesture(
                DragGesture()
                    .onChanged { g in
                        cropRect = CropMath.resize(cropRect, with: g.translation, corner: corner, bounds: bounds)
                    },
            )
    }

    private func edgeHandle(_ edge: Edge) -> some View {
        Rectangle()
            .fill(.clear)
            .frame(width: edge.isVertical ? 30 : nil, height: edge.isHorizontal ? 30 : nil)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { g in
                        cropRect = CropMath.resizeEdge(cropRect, with: g.translation, edge: edge, bounds: bounds)
                    },
            )
    }

    enum Corner { case topLeft, topRight, bottomLeft, bottomRight }
    enum Edge { case top, bottom, left, right
        var isVertical: Bool { self == .left || self == .right }
        var isHorizontal: Bool { self == .top || self == .bottom }
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

enum CropMath {
    static func clamp(_ rect: CGRect, in bounds: CGRect, minSize: CGFloat = 40) -> CGRect {
        var r = rect
        r.size.width = max(r.width, minSize)
        r.size.height = max(r.height, minSize)
        if r.minX < bounds.minX { r.origin.x = bounds.minX }
        if r.minY < bounds.minY { r.origin.y = bounds.minY }
        if r.maxX > bounds.maxX { r.origin.x = bounds.maxX - r.width }
        if r.maxY > bounds.maxY { r.origin.y = bounds.maxY - r.height }
        return r
    }

    static func resize(_ rect: CGRect, with t: CGSize, corner: CropOverlay.Corner, bounds: CGRect, minSize: CGFloat = 40) -> CGRect {
        var r = rect
        switch corner {
        case .topLeft:
            r.origin.x += t.width; r.size.width -= t.width
            r.origin.y += t.height; r.size.height -= t.height
        case .topRight:
            r.size.width += t.width
            r.origin.y += t.height; r.size.height -= t.height
        case .bottomLeft:
            r.origin.x += t.width; r.size.width -= t.width
            r.size.height += t.height
        case .bottomRight:
            r.size.width += t.width
            r.size.height += t.height
        }
        if r.width < minSize { r.size.width = minSize; if corner == .topLeft || corner == .bottomLeft { r.origin.x = rect.maxX - minSize } }
        if r.height < minSize { r.size.height = minSize; if corner == .topLeft || corner == .topRight { r.origin.y = rect.maxY - minSize } }
        return clamp(r, in: bounds, minSize: minSize)
    }

    static func resizeEdge(_ rect: CGRect, with t: CGSize, edge: CropOverlay.Edge, bounds: CGRect, minSize: CGFloat = 40) -> CGRect {
        var r = rect
        switch edge {
        case .top:
            r.origin.y += t.height; r.size.height -= t.height
        case .bottom:
            r.size.height += t.height
        case .left:
            r.origin.x += t.width; r.size.width -= t.width
        case .right:
            r.size.width += t.width
        }
        if r.width < minSize { r.size.width = minSize; if edge == .left { r.origin.x = rect.maxX - minSize } }
        if r.height < minSize { r.size.height = minSize; if edge == .top { r.origin.y = rect.maxY - minSize } }
        return clamp(r, in: bounds, minSize: minSize)
    }
}

enum ImageFitter {
    static func fittedRect(contentSize: CGSize, in container: CGSize) -> CGSize {
        let scale = min(container.width / max(contentSize.width, 1), container.height / max(contentSize.height, 1))
        return CGSize(width: contentSize.width * scale, height: contentSize.height * scale)
    }
}

// MARK: - Vision auto-crop with perspective correction

enum VisionAutoCropper {
    static func detectAndCorrectPerspective(image: UIImage, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let cg = image.cgImage else {
            completion(.failure(NSError(domain: "no_cg", code: -1))); return
        }
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumConfidence = 0.6
        request.minimumAspectRatio = 0.3

        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
                if let rect = (request.results as? [VNRectangleObservation])?.first {
                    let corrected = CIPerspective.correct(image: image, observation: rect)
                    if let corrected { completion(.success(corrected)) } else { completion(.failure(NSError(domain: "ci_fail", code: -2))) }
                } else {
                    completion(.failure(NSError(domain: "no_rect", code: -3)))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

enum CIPerspective {
    static func correct(image: UIImage, observation: VNRectangleObservation) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let ci = CIImage(cgImage: cg)
        let w = ci.extent.width
        let h = ci.extent.height

        func denorm(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * w, y: (1 - p.y) * h) }

        let tl = denorm(observation.topLeft)
        let tr = denorm(observation.topRight)
        let br = denorm(observation.bottomRight)
        let bl = denorm(observation.bottomLeft)

        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return nil }
        filter.setValue(ci, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: tl), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: tr), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: br), forKey: "inputBottomRight")
        filter.setValue(CIVector(cgPoint: bl), forKey: "inputBottomLeft")

        let ctx = CIContext(options: nil)
        guard let out = filter.outputImage,
              let cgOut = ctx.createCGImage(out, from: out.extent) else { return nil }
        return UIImage(cgImage: cgOut, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - UIImage helpers (rotate/crop)

extension UIImage {
    func rotated(byDegrees degrees: CGFloat) -> UIImage? {
        let radians = degrees * .pi / 180
        var newRect = CGRect(origin: .zero, size: size).applying(CGAffineTransform(rotationAngle: radians))
        newRect.origin = .zero

        UIGraphicsBeginImageContextWithOptions(newRect.size, false, scale)
        guard let ctx = UIGraphicsGetCurrentContext(), let cg = cgImage else { return nil }
        ctx.translateBy(x: newRect.width / 2, y: newRect.height / 2)
        ctx.rotate(by: radians)
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(cg, in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }

    func cropped(to rect: CGRect) -> UIImage? {
        guard let cg = cgImage else { return nil }
        let safeRect = CGRect(x: max(0, rect.origin.x), y: max(0, rect.origin.y), width: min(CGFloat(cg.width) - rect.origin.x, rect.width), height: min(CGFloat(cg.height) - rect.origin.y, rect.height)).integral
        guard let crop = cg.cropping(to: safeRect) else { return nil }
        return UIImage(cgImage: crop, scale: scale, orientation: imageOrientation)
    }
}

// MARK: - Quick Preview (remove in production)

struct ImageEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let demo = UIImage(systemName: "doc.text")!
            .withTintColor(.label, renderingMode: .alwaysOriginal)
        ImageEditorView(original: demo) { _ in }
            .preferredColorScheme(.dark)
    }
}
