import SwiftUI
import AVFoundation

/// Echte barcode-scanner met AVFoundation.
struct BarcodeScannerView: View {
    var onScan: (String?) -> Void
    @State private var permissionDenied = false

    var body: some View {
        ZStack {
            ScannerRepresentable(onScan: onScan, permissionDenied: $permissionDenied)
                .ignoresSafeArea()
            VStack {
                HStack {
                    Button("Sluit") { onScan(nil) }
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding()
                    Spacer()
                }
                Spacer()
                if permissionDenied {
                    Text("Camera-toegang geweigerd. Sta toegang toe in Instellingen.")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                }
            }
        }
    }
}

private struct ScannerRepresentable: UIViewRepresentable {
    var onScan: (String?) -> Void
    @Binding var permissionDenied: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    func makeUIView(context: Context) -> PreviewContainer {
        let view = PreviewContainer()
        context.coordinator.setupPreview(in: view) { denied in
            DispatchQueue.main.async { permissionDenied = denied }
        }
        return view
    }

    func updateUIView(_ uiView: PreviewContainer, context: Context) {
        uiView.previewLayer?.frame = uiView.bounds
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private let session = AVCaptureSession()
        private let metadataOutput = AVCaptureMetadataOutput()
        private var onScan: (String?) -> Void

        init(onScan: @escaping (String?) -> Void) {
            self.onScan = onScan
            super.init()
        }

        func setupPreview(in view: PreviewContainer, permissionHandler: @escaping (Bool) -> Void) {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                configureSession(in: view)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        granted ? self.configureSession(in: view) : permissionHandler(true)
                    }
                }
            default:
                permissionHandler(true)
            }
        }

        private func configureSession(in view: PreviewContainer) {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input),
                  session.canAddOutput(metadataOutput) else {
                onScan(nil)
                return
            }

            session.addInput(input)
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .qr, .code128, .dataMatrix, .upce]

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            view.previewLayer = previewLayer

            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let code = object.stringValue else { return }
            session.stopRunning()
            onScan(code)
        }
    }
}

private final class PreviewContainer: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
