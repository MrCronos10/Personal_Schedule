import UIKit
import Vision

/// One line Vision found on a photographed page, and where it sat.
///
/// `y` is Vision's own normalized coordinate — 0 at the bottom of the image, 1 at the top — kept
/// rather than the raw `VNRecognizedTextObservation` so the ordering rule below can be tested without
/// a real image or a real Vision request.
struct RecognizedLine: Equatable {
    let text: String
    let y: CGFloat
}

/// Recognises Simplified Chinese text in a photographed **Article**, entirely on the device — no
/// upload, no network request, keeping faith with why the app is native in the first place
/// (ADR 0001).
///
/// Takes no `ModelContext` and never calls `ArticleLibrary`: recognizing text is not importing it,
/// and the result always lands back in the same editable field a pasted Article already goes
/// through, never saved directly. A misread character is exactly the "a wrong reading is worse than
/// none" mistake `Vocabulary/SOURCE.md` already argues against, reached from a camera instead of a
/// bundled word list.
enum TextRecognizer {
    /// Turns what Vision found into one block of text, top of the image first.
    ///
    /// Vision doesn't promise its results in reading order, so this sorts by vertical position before
    /// joining. A line that is only whitespace is dropped rather than left as a blank row.
    static func joinedText(from lines: [RecognizedLine]) -> String {
        lines
            .sorted { $0.y > $1.y }
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    /// Recognises text in `image` and returns it joined and ordered. An image with nothing
    /// recognizable on it returns an empty string, the ordinary answer, not a thrown error — this
    /// only throws if Vision itself could not run at all.
    static func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { return "" }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImagePropertyOrientation)
        try handler.perform([request])

        let lines = (request.results ?? []).compactMap { observation -> RecognizedLine? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return RecognizedLine(text: candidate.string, y: observation.boundingBox.origin.y)
        }
        return joinedText(from: lines)
    }
}

private extension UIImage {
    /// Vision reads pixels, not a `UIImage`'s own notion of orientation, so a photo taken sideways
    /// has to say which way is actually up or Vision will recognise it rotated.
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }
}
