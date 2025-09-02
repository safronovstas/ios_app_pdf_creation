// import UIKit
// import CoreImage
//
// enum ImageEnhancer {
//    private static let context = CIContext()
//
//    static func enhance(_ image: UIImage) -> UIImage {
//        let ciImage = CIImage(image: image) ?? CIImage()
//
//        if let filter = CIFilter(name: "CIDocumentEnhancer") {
//            filter.setValue(ciImage, forKey: kCIInputImageKey)
//            if let output = filter.outputImage,
//               let cgImage = context.createCGImage(output, from: output.extent) {
//                return UIImage(cgImage: cgImage)
//            }
//        }
//
//        // Fallback simple contrast adjustment
//        if let filter = CIFilter(name: "CIColorControls") {
//            filter.setValue(ciImage, forKey: kCIInputImageKey)
//            filter.setValue(0.0, forKey: kCIInputSaturationKey)
//            filter.setValue(1.1, forKey: kCIInputContrastKey)
//            if let output = filter.outputImage,
//               let cgImage = context.createCGImage(output, from: output.extent) {
//                return UIImage(cgImage: cgImage)
//            }
//        }
//
//        return image
//    }
// }
