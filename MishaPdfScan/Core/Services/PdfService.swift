// Core/Services/PdfService.swift
import UIKit
import UniformTypeIdentifiers

struct PdfService {
    /// PDF как Data (для fileExporter / ShareLink)
    func makePDFData(images: [UIImage],
                     pageSize: CGSize = CGSize(width: 595, height: 842),   // A4 @72dpi
                     margins: UIEdgeInsets = .init(top: 24, left: 24, bottom: 24, right: 24)) -> Data {
        let bounds = CGRect(origin: .zero, size: pageSize)
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
        return renderer.pdfData { ctx in
            for img in images {
                ctx.beginPage()
                let rect = bounds.inset(by: margins)
                let scale = min(rect.width / max(img.size.width, 1),
                                rect.height / max(img.size.height, 1))
                let size  = CGSize(width: img.size.width * scale, height: img.size.height * scale)
                let draw  = CGRect(x: rect.midX - size.width/2,
                                   y: rect.midY - size.height/2,
                                   width: size.width, height: size.height)
                img.draw(in: draw)
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

    static func defaultFilename(prefix: String = "Scan") -> String {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return "\(prefix)_\(df.string(from: Date())).pdf"
    }
}
