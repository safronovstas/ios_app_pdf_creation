// import SwiftUI
// import AVFoundation
//
// struct CameraScannerView: View {
//    var completion: ([UIImage]) -> Void
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var model = CameraScannerModel()
//
//    var body: some View {
//        ZStack {
//            CameraPreview(session: model.session)
//                .ignoresSafeArea()
//
//            VStack {
//                Picker("Camera", selection: $model.selectedDeviceID) {
//                    ForEach(model.availableDevices, id: \.uniqueID) { device in
//                        Text(device.localizedName).tag(device.uniqueID)
//                    }
//                }
//                .pickerStyle(MenuPickerStyle())
//                .padding()
//                .onChange(of: model.selectedDeviceID) { _ in
//                    model.updateSelectedDevice()
//                }
//
//                Spacer()
//
//                HStack {
//                    Button(action: model.capturePhoto) {
//                        Image(systemName: "camera.circle.fill")
//                            .resizable()
//                            .frame(width: 64, height: 64)
//                            .foregroundColor(.white)
//                    }
//                    .padding()
//
//                    Button("Done") {
//                        dismiss()
//                        completion(model.capturedImages)
//                        model.stopSession()
//                    }
//                    .padding()
//                    .background(Color.black.opacity(0.5))
//                    .foregroundColor(.white)
//                    .clipShape(Capsule())
//                }
//                .padding(.bottom)
//            }
//        }
//        .onAppear {
//            model.setupSession()
//            model.startSession()
//        }
//        .onDisappear {
//            model.stopSession()
//        }
//    }
// }
//
// final class CameraScannerModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
//    @Published var session = AVCaptureSession()
//    @Published var availableDevices: [AVCaptureDevice] = []
//    @Published var selectedDeviceID: String = ""
//    @Published var capturedImages: [UIImage] = []
//
//    private let photoOutput = AVCapturePhotoOutput()
//
//    func setupSession() {
//        let discovery = AVCaptureDevice.DiscoverySession(
//            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera],
//            mediaType: .video,
//            position: .unspecified
//        )
//        availableDevices = discovery.devices
//        if let first = availableDevices.first {
//            selectedDeviceID = first.uniqueID
//            configureInput(device: first)
//        }
//        if session.canAddOutput(photoOutput) {
//            session.addOutput(photoOutput)
//        }
//    }
//
//    func updateSelectedDevice() {
//        guard let device = availableDevices.first(where: { $0.uniqueID == selectedDeviceID }) else { return }
//        configureInput(device: device)
//    }
//
//    private func configureInput(device: AVCaptureDevice) {
//        session.beginConfiguration()
//        for input in session.inputs {
//            session.removeInput(input)
//        }
//        if let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) {
//            session.addInput(input)
//        }
//        session.commitConfiguration()
//    }
//
//    func startSession() {
//        if !session.isRunning {
//            DispatchQueue.global(qos: .background).async {
//                self.session.startRunning()
//            }
//        }
//    }
//
//    func stopSession() {
//        if session.isRunning {
//            session.stopRunning()
//        }
//    }
//
//    func capturePhoto() {
//        let settings = AVCapturePhotoSettings()
//        photoOutput.capturePhoto(with: settings, delegate: self)
//    }
//
//    func photoOutput(_ output: AVCapturePhotoOutput,
//                     didFinishProcessingPhoto photo: AVCapturePhoto,
//                     error: Error?) {
//        guard error == nil,
//              let data = photo.fileDataRepresentation(),
//              let image = UIImage(data: data) else { return }
//        let enhanced = ImageEnhancer.enhance(image)
//        capturedImages.append(enhanced)
//    }
// }
//
// struct CameraPreview: UIViewRepresentable {
//    let session: AVCaptureSession
//
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView(frame: UIScreen.main.bounds)
//        let preview = AVCaptureVideoPreviewLayer(session: session)
//        preview.videoGravity = .resizeAspectFill
//        preview.frame = view.bounds
//        view.layer.addSublayer(preview)
//        return view
//    }
//
//    func updateUIView(_ uiView: UIView, context: Context) {}
// }
