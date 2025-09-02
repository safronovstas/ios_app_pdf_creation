import AVFoundation
import PhotosUI // ✅ нужно для PHPicker
import SwiftUI
import UIKit // ✅ нужно для UIImagePickerControllerDelegate
import Vision

struct PhotoPickerSheet: UIViewControllerRepresentable {
    let controller: CameraController
    func makeUIViewController(context _: Context) -> PHPickerViewController {
        var cfg = PHPickerConfiguration(photoLibrary: .shared())
        cfg.filter = .images
        cfg.selectionLimit = 0 // 0 = без лимита
        let picker = PHPickerViewController(configuration: cfg)
        picker.delegate = controller // ВАЖНО: делегат — та же живая инстанция
        return picker
    }

    func updateUIViewController(_: PHPickerViewController, context _: Context) {}
}
