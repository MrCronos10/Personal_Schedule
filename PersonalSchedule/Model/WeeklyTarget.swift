import Foundation

/// The Weekly Target, as the student reads it. Minutes are what is stored and typed, because that is the
/// language CONTEXT.md is written in; hours are only ever shown back, never parsed.
enum WeeklyTarget {
    /// 420 minutes as "7", 450 as "7.5". The decimal point is written the same way everywhere, because the
    /// number sits inside a sentence and a region that writes "7,5" would read as two numbers.
    static func hoursText(forMinutes minutes: Int) -> String {
        let text = String(format: "%.1f", Double(minutes) / 60)
        return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
    }
}
