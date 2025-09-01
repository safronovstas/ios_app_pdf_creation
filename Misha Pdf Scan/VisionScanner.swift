import UIKit
import Vision
import CoreImage

enum VisionScanner {
    static func detectAndCorrect(image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return nil }

        let req = VNDetectRectanglesRequest()
        req.maximumObservations = 1
        req.minimumConfidence = 0.6
        req.minimumAspectRatio = 0.3

        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        try? handler.perform([req])

        guard let rect = (req.results as? [VNRectangleObservation])?.first else { return image }

        let ci = CIImage(cgImage: cg)
        let width = ci.extent.width
        let height = ci.extent.height

        // точки VN* нормализованы (0..1), преобразуем в пиксели CI
        let tl = rect.topLeft.scaled(width: width, height: height)
        let tr = rect.topRight.scaled(width: width, height: height)
        let br = rect.bottomRight.scaled(width: width, height: height)
        let bl = rect.bottomLeft.scaled(width: width, height: height)

        let filter = CIFilter(name: "CIPerspectiveCorrection")!
        filter.setValue(ci, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: tl), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: tr), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: bl), forKey: "inputBottomLeft")
        filter.setValue(CIVector(cgPoint: br), forKey: "inputBottomRight")

        guard let out = filter.outputImage else { return image }

        let ctx = CIContext()
        if let cgOut = ctx.createCGImage(out, from: out.extent) {
            return UIImage(cgImage: cgOut, scale: image.scale, orientation: image.imageOrientation)
        }
        return image
    }
}

// умножение пригодится, но не обязательно
private extension CGPoint {
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint { .init(x: lhs.x * rhs, y: lhs.y * rhs) }

    // Перевод нормализованных координат VN (origin снизу-слева) в пиксели CI.
    func scaled(width: CGFloat, height: CGFloat) -> CGPoint {
        CGPoint(x: x * width, y: (1 - y) * height)
    }
}
