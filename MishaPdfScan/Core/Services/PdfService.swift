import UIKit

struct PdfExportOptions: Equatable {
    /// JPEG качество [0.0...1.0] — меньше = сильнее компрессия (меньше файл)
    var jpegQuality: CGFloat = 0.65
    /// Ограничение длинной стороны изображения (px). 0 — не ограничивать.
    var maxLongSide: CGFloat = 2400

    static let `default` = PdfExportOptions()
}

struct PdfService {
    /// Сконвертировать массив изображений в PDF c учётом опций
    func makePDFData(images: [UIImage],
                     options: PdfExportOptions,
                     pageSize: CGSize = .init(width: 595, height: 842),   // A4 @72dpi
                     margins: UIEdgeInsets = .init(top: 24, left: 24, bottom: 24, right: 24)) -> Data {

        let bounds = CGRect(origin: .zero, size: pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: UIGraphicsPDFRendererFormat())

        return renderer.pdfData { ctx in
            for img in images {
                ctx.beginPage()

                // 1) даунсемплим до maxLongSide (если задан)
                let down = downsample(img, maxLongSide: options.maxLongSide)
                // 2) recompress -> JPEG (в PDF уйдёт уже сжатое изображение)
                let processed = (down.jpegData(compressionQuality: options.jpegQuality)).flatMap(UIImage.init(data:)) ?? down

                // рисуем по центру в прямоугольник с полями
                let rect = bounds.inset(by: margins)
                let scale = min(rect.width / max(processed.size.width, 1),
                                rect.height / max(processed.size.height, 1))
                let size  = CGSize(width: processed.size.width * scale,
                                   height: processed.size.height * scale)
                let draw  = CGRect(x: rect.midX - size.width/2,
                                   y: rect.midY - size.height/2,
                                   width: size.width, height: size.height)
                processed.draw(in: draw)
            }
        }
    }

    /// Сохранить PDF в Caches/Exports и вернуть URL
    func writePDFToCaches(_ data: Data, filename: String) throws -> URL {
        let fm = FileManager.default
        let dir = try fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Exports", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        var url = dir.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
        return url
    }

    func writePDFToDocuments(_ data: Data, filename: String) throws -> URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("Scans", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) { try fm.createDirectory(at: dir, withIntermediateDirectories: true) }
        let url = dir.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }
    
    static func defaultFilename(prefix: String = "Scan") -> String {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return "\(prefix)_\(df.string(from: Date())).pdf"
    }

    // MARK: - helpers
    private func downsample(_ image: UIImage, maxLongSide: CGFloat) -> UIImage {
        guard maxLongSide > 0 else { return image }
        let longSide = max(image.size.width, image.size.height)
        guard longSide > maxLongSide else { return image }
        let scale = maxLongSide / longSide
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let r = UIGraphicsImageRenderer(size: newSize)
        return r.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
