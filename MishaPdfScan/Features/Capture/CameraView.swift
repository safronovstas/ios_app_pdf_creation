//
//  CameraView.swift
//  Misha Pdf Scan
//
//  Created by mac air on 9/1/25.
//
import AVFoundation
import PhotosUI
import SwiftUI
import UIKit // ✅ нужно для UIImagePickerControllerDelegate
import Vision

struct CameraView: UIViewRepresentable {
    let controller: CameraController
    func makeUIView(context _: Context) -> PreviewView { PreviewView(layer: controller.makePreviewLayer()) }
    func updateUIView(_: PreviewView, context _: Context) {}
}
