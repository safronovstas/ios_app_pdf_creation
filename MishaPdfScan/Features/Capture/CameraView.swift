//
//  CameraView.swift
//  Misha Pdf Scan
//
//  Created by mac air on 9/1/25.
//
import SwiftUI
import AVFoundation
import Vision
import UIKit          // ✅ нужно для UIImagePickerControllerDelegate
import PhotosUI

struct CameraView: UIViewRepresentable {
    let controller: CameraController
    func makeUIView(context: Context) -> PreviewView { PreviewView(layer: controller.makePreviewLayer()) }
    func updateUIView(_ uiView: PreviewView, context: Context) {}
}
