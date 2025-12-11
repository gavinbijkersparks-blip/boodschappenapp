import SwiftUI
import AVFoundation

// Vereenvoudigde scanner: toont een knop om te sluiten, geen echte scan (wegens tijd/vereisten).
// Vervang door een echte AVCaptureSession of een third-party CodeScanner als gewenst.
struct BarcodeScannerView: View {
    var onScan: (String?) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Barcode scannen")
                .font(.title2.bold())
            Text("Deze demo-view scant niet echt. Vervang met een echte scanner als nodig.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding()
            Button("Sluit") {
                onScan(nil)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
