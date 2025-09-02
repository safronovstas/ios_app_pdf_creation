import AVFoundation
import PhotosUI // ✅ нужно для PHPicker
import SwiftUI
import UIKit // ✅ нужно для UIImagePickerControllerDelegate
import Vision

final class PreviewView: UIView {
    let previewLayer: AVCaptureVideoPreviewLayer
    init(layer: AVCaptureVideoPreviewLayer) {
        previewLayer = layer
        super.init(frame: .zero)
        self.layer.addSublayer(previewLayer)
        previewLayer.videoGravity = .resizeAspectFill
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
