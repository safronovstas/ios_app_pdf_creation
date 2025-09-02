// =====================================
// Core/Utils/UIImage+EditHelpers.swift
// =====================================
import UIKit


public extension UIImage {
    func rotated(byDegrees degrees: CGFloat) -> UIImage? {
        let radians = degrees * .pi / 180
        var newRect = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
        newRect.origin = .zero
        UIGraphicsBeginImageContextWithOptions(newRect.size, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext(), let cg = self.cgImage else { return nil }
        ctx.translateBy(x: newRect.width/2, y: newRect.height/2)
        ctx.rotate(by: radians)
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(cg, in: CGRect(x: -size.width/2, y: -size.height/2, width: size.width, height: size.height))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    func cropped(to rect: CGRect) -> UIImage? {
        guard let cg = self.cgImage else { return nil }
        let safe = CGRect(x: max(0, rect.origin.x), y: max(0, rect.origin.y),
                          width: min(CGFloat(cg.width) - rect.origin.x, rect.width),
                          height: min(CGFloat(cg.height) - rect.origin.y, rect.height)).integral
        guard let crop = cg.cropping(to: safe) else { return nil }
        return UIImage(cgImage: crop, scale: self.scale, orientation: self.imageOrientation)
    }
}
