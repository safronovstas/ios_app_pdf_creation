//
//  CameraController.swift
//  Misha Pdf Scan
//
//  Created by mac air on 9/1/25.
//

import SwiftUI
import AVFoundation
import Vision
import UIKit          // ✅ нужно для UIImagePickerControllerDelegate
import PhotosUI       // ✅ нужно для PHPicker

class CameraController: NSObject, ObservableObject,
                        AVCapturePhotoCaptureDelegate,
                        UIImagePickerControllerDelegate,
                        UINavigationControllerDelegate {

    @Published var authorized = false
    @Published var running = false
    @Published var capturedImage: UIImage?

    /// ✅ колбэк для множественного выбора из PHPicker
       var onPickedImages: (([UIImage]) -> Void)?

    
    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "camera.session")

    // ✅ Кросс-версионная авторизация камеры
    func start() {
        if #available(iOS 17.0, *) {
            Task { @MainActor in
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                self.authorized = granted
                guard granted else { return }
                self.startSession()
            }
        } else {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.authorized = granted
                    guard granted else { return }
                    self.startSession()
                }
            }
        }
    }
    
    
    private func startSession() {
        queue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
               let input = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }

            self.session.commitConfiguration()
            self.session.startRunning()
            DispatchQueue.main.async { self.running = true }
        }
    }

    func stop() {
        queue.async {
            self.session.stopRunning()
            DispatchQueue.main.async { self.running = false }
        }
    }

    func capture() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
     func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
         if let data = photo.fileDataRepresentation(), let ui = UIImage(data: data) {
             handleCaptured(image: ui)
         }
     }

    // MARK: - UIImagePickerControllerDelegate (одиночный выбор)
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let img = info[.originalImage] as? UIImage {
            handleCaptured(image: img)
        }
    }

    private func handleCaptured(image: UIImage) {
        // Detect rectangle and deskew
        let corrected = VisionScanner.detectAndCorrect(image: image) ?? image
        DispatchQueue.main.async { self.capturedImage = corrected }
    }

    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        AVCaptureVideoPreviewLayer(session: session)
    }}

@available(iOS 14.0, *)
extension CameraController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        var images: [UIImage] = []
        let group = DispatchGroup()

        for r in results {
            if r.itemProvider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                r.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                    if let img = obj as? UIImage {
                        // при желании тут можно даунскейлить/нормализовать ориентацию
                        images.append(img)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.onPickedImages?(images)   // вернём массив выбранных картинок
        }
    }
}
