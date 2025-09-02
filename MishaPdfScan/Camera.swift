import SwiftUI
import AVFoundation
import Vision
import UIKit          // ✅ нужно для UIImagePickerControllerDelegate
import PhotosUI       // ✅ нужно для PHPicker


final class PreviewView: UIView {
    let previewLayer: AVCaptureVideoPreviewLayer
    init(layer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = layer
        super.init(frame: .zero)
        self.layer.addSublayer(previewLayer)
        previewLayer.videoGravity = .resizeAspectFill
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
