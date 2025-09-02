import UIKit

enum PDFExporter {
    @discardableResult
    static func export(images: [UIImage], filename: String) -> URL {
        let fmt = UIGraphicsPDFRendererFormat()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: url.path) { try? FileManager.default.removeItem(at: url) }
        if images.isEmpty { return url }
        let pageRect = CGRect(origin: .zero, size: images[0].size)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: fmt)
        try? renderer.writePDF(to: url) { ctx in
            for img in images {
                ctx.beginPage(); img.draw(in: CGRect(origin: .zero, size: img.size))
            }
        }
        return url
    }
}
