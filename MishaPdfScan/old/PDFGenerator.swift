// import UIKit
// import PDFKit
//
// enum PDFGenerator {
//    static func createPDF(from images: [UIImage]) -> URL? {
//        let document = PDFDocument()
//        for (index, image) in images.enumerated() {
//            guard let page = PDFPage(image: image) else { continue }
//            document.insert(page, at: index)
//        }
//        let url = FileManager.default.temporaryDirectory.appendingPathComponent("scan.pdf")
//        document.write(to: url)
//        return url
//    }
// }
