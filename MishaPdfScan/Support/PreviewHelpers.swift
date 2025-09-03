// Support/PreviewHelpers.swift
import SwiftUI
import PDFKit

enum PreviewHelpers {
    static func placeholderImage(size: CGSize = .init(width: 600, height: 800),
                                 color: UIColor = .systemBlue,
                                 text: String = "Page") -> UIImage {
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            color.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 64),
                .foregroundColor: UIColor.white
            ]
            let str = NSAttributedString(string: text, attributes: attrs)
            let b = str.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil)
            let rect = CGRect(x: (size.width - b.width)/2, y: (size.height - b.height)/2, width: b.width, height: b.height)
            str.draw(in: rect)
        }
    }

    @discardableResult
    static func makeSamplePDF(pages: Int = 1, filename: String = "Sample.pdf") throws -> URL {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent(filename)
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        try renderer.writePDF(to: url) { ctx in
            for i in 1...max(1, pages) {
                ctx.beginPage()
                let s = "Sample PDF \(i)"
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                    .foregroundColor: UIColor.black
                ]
                let str = NSAttributedString(string: s, attributes: attrs)
                str.draw(at: CGPoint(x: 72, y: 72))
            }
        }
        return url
    }

    @discardableResult
    static func makeSamplePDFInScans(named: String) throws -> URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("Scans", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) { try fm.createDirectory(at: dir, withIntermediateDirectories: true) }
        let url = dir.appendingPathComponent(named)
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        try renderer.writePDF(to: url) { ctx in
            ctx.beginPage()
            let s = "Preview Sample"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor.black
            ]
            let str = NSAttributedString(string: s, attributes: attrs)
            str.draw(at: CGPoint(x: 72, y: 72))
        }
        return url
    }
}

extension PagesStore {
    static func preview(withPages count: Int = 3) -> PagesStore {
        let s = PagesStore()
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPink, .systemPurple]
        let imgs: [UIImage] = (0..<count).map { i in
            PreviewHelpers.placeholderImage(color: colors[i % colors.count], text: "\(i+1)")
        }
        Task { @MainActor in s.add(images: imgs) }
        return s
    }
}

extension HistoryStore {
    static func previewWithSamples(count: Int = 2) -> HistoryStore {
        let s = HistoryStore()
        // create a few sample PDFs in Documents/Scans
        for i in 1...count {
            let name = String(format: "Sample_%02d.pdf", i)
            _ = try? PreviewHelpers.makeSamplePDFInScans(named: name)
        }
        Task { @MainActor in s.refresh() }
        return s
    }
}

