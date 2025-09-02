// Features/Capture/CameraScreen.swift
import SwiftUI
import AVFoundation

// Какие «типы» задней камеры показываем в UI
enum BackCameraType: String, CaseIterable, Identifiable {
    case ultraWide, wide, tele
    var id: Self { self }
    var title: String {
        switch self {
        case .ultraWide: return "0.5×"
        case .wide:      return "1×"
        case .tele:      return "2×"
        }
    }
    var deviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .ultraWide: return .builtInUltraWideCamera
        case .wide:      return .builtInWideAngleCamera
        case .tele:      return .builtInTelephotoCamera
        }
    }
}

struct CameraScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraManager()
    @State private var selection: BackCameraType? = nil
    @State private var pinchStartZoom: CGFloat = 1

    let onCapture: (UIImage?) -> Void

    var body: some View {
        ZStack {
            // превью
            CameraPreview(session: camera.session)
                .ignoresSafeArea()
                // Пинч-зум
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let target = pinchStartZoom * value
                            camera.setZoom(target)
                        }
                        .onEnded { _ in
                            pinchStartZoom = camera.zoom
                        }
                )

            VStack(spacing: 0) {
                // Верхняя панель: закрыть + выбор объектива
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 28))
                    }
                    .padding(.leading, 12)

                    Spacer()

                    // Сегментированный выбор доступных камер
                    if !camera.availableBackTypes.isEmpty {
                        Picker("Камера", selection: Binding(
                            get: { selection ?? camera.selectedType },
                            set: { newValue in
                                selection = newValue
                                if let t = newValue { camera.selectCamera(t) }
                            })
                        ) {
                            ForEach(camera.availableBackTypes) { t in
                                Text(t.title).tag(Optional(t))
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                        .padding(.trailing, 12)
                        .onChange(of: camera.selectedType) { new in
                            // Синхронизируем локальный selection, если камера изменилась изнутри
                            if selection != new { selection = new }
                        }
                    }
                }
                .padding(.top, 8)
                .foregroundStyle(.white)

                Spacer()

                // Нижняя панель: зум-слайдер + кнопка спуска
                VStack(spacing: 16) {
                    // Слайдер зума
                    if camera.maxZoom > camera.minZoom {
                        HStack {
                            Image(systemName: "minus.magnifyingglass")
                            Slider(value: Binding(
                                get: { camera.zoom },
                                set: { camera.setZoom($0) }
                            ), in: camera.minZoom...camera.maxZoom)
                            Image(systemName: "plus.magnifyingglass")
                        }
                        .padding(.horizontal)
                        .foregroundStyle(.white)
                    }

                    Button { camera.capture() } label: {
                        Circle().stroke(lineWidth: 6).frame(width: 80, height: 80)
                    }
                    .padding(.bottom, 24)
                    .foregroundStyle(.white)
                }
            }
        }
        .onAppear {
            camera.start()                           // запрос доступа + старт сессии
            camera.autoSelectPreferredCamera()       // фолбэк: wide → ultraWide → tele
            pinchStartZoom = camera.zoom
        }
        .onDisappear { camera.stop() }
        .onChange(of: camera.captured) { img in
            if let img { onCapture(img) }
        }
    }
}

// MARK: - Manager

final class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var captured: UIImage?
    @Published var availableBackTypes: [BackCameraType] = []
    @Published var selectedType: BackCameraType? = nil

    // Зум
    @Published var zoom: CGFloat = 1
    @Published var minZoom: CGFloat = 1
    @Published var maxZoom: CGFloat = 1

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "camera.session")
    private var currentDevice: AVCaptureDevice?

    // MARK: lifecycle
    func start() {
        discoverBackCameras()
        func configureAndStart() {
            queue.async {
                self.session.beginConfiguration()
                self.session.sessionPreset = .photo
                if self.session.canAddOutput(self.output) { self.session.addOutput(self.output) }
                self.session.commitConfiguration()
                self.session.startRunning()
            }
        }
        if #available(iOS 17.0, *) {
            Task { @MainActor in
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                guard granted else { return }
                configureAndStart()
            }
        } else {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else { return }
                configureAndStart()
            }
        }
    }

    func stop() { queue.async { self.session.stopRunning() } }

    // MARK: capture
    func capture() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(), let ui = UIImage(data: data) {
            DispatchQueue.main.async { self.captured = ui }
        }
    }

    // MARK: discovery & selection
    private func discoverBackCameras() {
        let ds = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: .back
        )
        let types = ds.devices.compactMap { d -> BackCameraType? in
            switch d.deviceType {
            case .builtInUltraWideCamera: return .ultraWide
            case .builtInWideAngleCamera: return .wide
            case .builtInTelephotoCamera: return .tele
            default: return nil
            }
        }
        // Уникальные и в желаемом порядке 0.5×, 1×, 2×
        let order: [BackCameraType] = [.ultraWide, .wide, .tele]
        let unique = order.filter { types.contains($0) }
        DispatchQueue.main.async { self.availableBackTypes = unique }
    }

    func autoSelectPreferredCamera() {
        // Предпочитаем wide, если не получится — ultraWide, затем tele
        let preference: [BackCameraType] = [.wide, .ultraWide, .tele]
        if let target = preference.first(where: { availableBackTypes.contains($0) }) {
            selectCamera(target)
        }
    }

    func selectCamera(_ type: BackCameraType) {
        queue.async {
            guard let device = self.findBackDevice(for: type) else { return }
            self.session.beginConfiguration()
            // удалить старые видео-инпуты
            for input in self.session.inputs {
                if let di = input as? AVCaptureDeviceInput, di.device.hasMediaType(.video) {
                    self.session.removeInput(di)
                }
            }
            // добавить новый
            if let input = try? AVCaptureDeviceInput(device: device), self.session.canAddInput(input) {
                self.session.addInput(input)
                self.currentDevice = device
                let minZ = device.minAvailableVideoZoomFactor
                let maxZ = device.maxAvailableVideoZoomFactor
                // сбросить/нормализовать зум
                do {
                    try device.lockForConfiguration()
                    device.videoZoomFactor = max(1, minZ)
                    device.unlockForConfiguration()
                } catch {}
                DispatchQueue.main.async {
                    self.selectedType = type
                    self.minZoom = max(1, minZ)
                    self.maxZoom = maxZ
                    self.zoom = max(1, minZ)
                }
            }
            self.session.commitConfiguration()
        }
    }

    private func findBackDevice(for type: BackCameraType) -> AVCaptureDevice? {
        let ds = AVCaptureDevice.DiscoverySession(
            deviceTypes: [type.deviceType],
            mediaType: .video,
            position: .back
        )
        return ds.devices.first
    }

    // MARK: zoom
    func setZoom(_ factor: CGFloat) {
        queue.async {
            guard let device = self.currentDevice else { return }
            let minF = device.minAvailableVideoZoomFactor
            let maxF = device.maxAvailableVideoZoomFactor
            let f = min(max(factor, minF), maxF)
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = f
                device.unlockForConfiguration()
                DispatchQueue.main.async { self.zoom = f }
            } catch {
                // ignore
            }
        }
    }
}

// MARK: - Preview host
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> PreviewView { PreviewView(session: session) }
    func updateUIView(_ uiView: PreviewView, context: Context) {}
}
final class PreviewView: UIView {
    let previewLayer: AVCaptureVideoPreviewLayer
    init(session: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init(frame: .zero)
        layer.addSublayer(previewLayer)
        previewLayer.videoGravity = .resizeAspectFill
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() { super.layoutSubviews(); previewLayer.frame = bounds }
}
