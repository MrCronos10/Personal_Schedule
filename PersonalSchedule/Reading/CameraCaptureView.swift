import AVFoundation
import SwiftUI
import UIKit

/// Whether the camera can actually be offered right now: present on this device, and permitted.
enum CameraAccess {
    /// False on the Simulator, and on any device with no camera at all. The 拍照 button is left off
    /// the import sheet entirely rather than shown disabled, since there is nothing a tap on it could
    /// ever do.
    static var isHardwareAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    /// Asks once if never asked before; otherwise reports the answer already on file, so the system
    /// prompt is never shown a second time behind the app's back.
    static func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

/// Captures one photo with the camera. Wraps `UIImagePickerController` because SwiftUI has no native
/// camera capture view; one image per import (ticket 07) — stitching several photos of a textbook
/// page together is a feature of its own, not a one-line add-on.
struct CameraCaptureView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView

        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
