import Foundation
import Testing
@testable import PersonalSchedule

/// Turning what Vision found on a photographed page into one block of text. Recognition itself needs
/// a camera and a real image, so it is checked by hand; what can be pinned is what happens to the
/// lines once Vision has found them.
struct TextRecognizerTests {
    /// Vision doesn't promise its results in reading order. `y` is Vision's own normalized
    /// coordinate, where 0 is the bottom of the image and 1 is the top — so top-to-bottom reading
    /// order is descending `y`, the opposite of how a list is usually sorted.
    @Test func linesAreOrderedTopToBottomByVerticalPosition() throws {
        let lines = [
            RecognizedLine(text: "第二行", y: 0.3),
            RecognizedLine(text: "第一行", y: 0.8),
            RecognizedLine(text: "第三行", y: 0.1),
        ]
        #expect(TextRecognizer.joinedText(from: lines) == "第一行\n第二行\n第三行")
    }

    /// A line that is only whitespace — a stray mark Vision mistook for text — is dropped rather than
    /// left as a blank row in the middle of the recognized text.
    @Test func blankLinesAreDropped() throws {
        let lines = [
            RecognizedLine(text: "正文", y: 0.5),
            RecognizedLine(text: "   ", y: 0.9),
        ]
        #expect(TextRecognizer.joinedText(from: lines) == "正文")
    }

    /// Recognizing nothing is an ordinary answer, not an error (ticket 07): an empty photo produces
    /// an empty string, the same value the import field starts with.
    @Test func noLinesProduceAnEmptyStringNotAnError() throws {
        #expect(TextRecognizer.joinedText(from: []) == "")
    }

    /// Each line is trimmed before joining, so leading or trailing spaces Vision sometimes reports
    /// don't survive into the editable text the student corrects.
    @Test func eachLineIsTrimmed() throws {
        let lines = [RecognizedLine(text: "  杭州西湖  ", y: 0.5)]
        #expect(TextRecognizer.joinedText(from: lines) == "杭州西湖")
    }
}
