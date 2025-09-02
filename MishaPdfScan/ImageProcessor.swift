import CoreImage
import UIKit

enum ImageProcessor {
    static func autoEnhance(image: UIImage) -> UIImage {
        guard let cg = image.cgImage else { return image }
        let ci = CIImage(cgImage: cg)
        let filters = ci.autoAdjustmentFilters(options: [CIImageAutoAdjustmentOption.enhance: true, CIImageAutoAdjustmentOption.redEye: false])
        let filtered = filters.reduce(ci) { $1.outputImage?.applyingFilter("CIColorControls", parameters: [kCIInputContrastKey: 1.1]) ?? $0 }
        let bw = filtered.applyingFilter("CIPhotoEffectNoir")
        let ctx = CIContext()
        guard let out = ctx.createCGImage(bw, from: bw.extent) else { return image }
        return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
    }
}
