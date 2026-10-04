import CoreGraphics
import Foundation

/// How far down an Article the student has read, as the width of the thin bar under its title.
enum ReadingProgress {
    /// 0 at the top, 1 at the bottom, clamped so overscroll never pushes the bar out of range. An
    /// Article that fits on the screen is fully read: there is nothing to scroll to.
    static func fraction(scrolled: CGFloat, content: CGFloat, viewport: CGFloat) -> Double {
        let scrollable = content - viewport
        guard scrollable > 0 else { return 1 }
        return Double(min(max(scrolled / scrollable, 0), 1))
    }
}

/// An Article split into the paragraphs the reader draws, so a tapped word's lookup card can sit
/// directly under the paragraph it belongs to.
enum ArticleParagraphs {
    /// The non-blank lines of `text`, in order, as ranges into it.
    static func ranges(in text: String) -> [Range<String.Index>] {
        text.split(separator: "\n", omittingEmptySubsequences: true)
            .filter { !$0.allSatisfy(\.isWhitespace) }
            .map { $0.startIndex..<$0.endIndex }
    }
}
