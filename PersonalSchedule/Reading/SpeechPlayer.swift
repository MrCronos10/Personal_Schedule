import AVFoundation
import SwiftUI

/// Speaks Chinese text aloud, entirely on the device: no audio files bundled, no network request,
/// keeping faith with why the app is native in the first place (ADR 0001).
///
/// Takes no `ModelContext` and reaches no `Article`, `WordLookup` or `WordProgress` — hearing a Word
/// is not evidence of anything, so nothing here could record a **Lookup**, a **Clean Sighting** or a
/// **Reading Session**'s minutes even by mistake. That is a guarantee the type cannot reach the
/// store, not a check that it chose not to, which is why there is no database assertion among its
/// tests: there is nothing in it capable of writing one.
@MainActor
final class SpeechPlayer: NSObject, ObservableObject {
    static let shared = SpeechPlayer()

    /// The Mandarin voice, asked for by its own language code rather than inherited from
    /// `LanguageSetting` or `Locale.current`. The app's UI language and the language Chinese text is
    /// spoken in are two different questions — a student reading the English interface still needs
    /// to hear Chinese as Chinese.
    nonisolated static let voiceLanguageCode = "zh-CN"

    private let synthesizer = AVSpeechSynthesizer()
    /// The text currently sounding, if any — not merely whether *something* is, so a button for one
    /// Word doesn't show itself as playing when a different Word or the whole Article is.
    @Published private(set) var currentText: String?

    /// Not private: tests need a fresh player, not `.shared`, so exercising `currentText` in one
    /// test can't leak into another.
    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Builds the utterance `speak(_:)` sends. Exposed so the voice-selection rule can be pinned by a
    /// test without needing real audio hardware.
    nonisolated static func utterance(for text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguageCode)
        return utterance
    }

    /// Speaks `text` aloud. Starting a new sound stops whatever was already playing rather than
    /// layering over it: only one Word or Article is ever being read at once.
    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        currentText = text
        synthesizer.speak(Self.utterance(for: text))
    }

    /// Stops playback outright.
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        currentText = nil
    }

    /// Stops playback only if `text` is the thing actually sounding. This is what a screen's
    /// `onDisappear` calls rather than `stop()`: `SpeechPlayer` is one shared player behind every
    /// speaker in the app, so leaving a Word sheet must not silence an Article narrating underneath
    /// it that the sheet itself never started.
    func stop(ifPlaying text: String) {
        guard currentText == text else { return }
        stop()
    }
}

extension SpeechPlayer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        clearIfStillCurrent(utterance)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        clearIfStillCurrent(utterance)
    }

    /// `speak(_:)` cancels whatever was already playing before starting the new utterance, and that
    /// cancellation's own `didCancel` fires *after* `speak(_:)` has already set `currentText` to the
    /// new text — delegate callbacks are only scheduled onto the actor, not run inline, so the old
    /// utterance's cleanup always lands after the new one has started. Without this guard, that stale
    /// cleanup would clear the *new* text and leave its button showing "play" while it is still
    /// audibly speaking.
    private nonisolated func clearIfStillCurrent(_ utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard self.currentText == utterance.speechString else { return }
            self.currentText = nil
        }
    }
}

/// A speaker that reads `text` aloud, becoming a stop button while it is the thing actually playing.
///
/// Hearing something is not a measurement (ADR 0005): this works for any Chinese text, including the
/// HSK 1-3 words and names the rest of the app doesn't carry state for.
struct SpeakerButton: View {
    @ObservedObject private var player = SpeechPlayer.shared

    let text: String

    private var isPlayingThis: Bool { player.currentText == text }

    var body: some View {
        Button {
            if isPlayingThis {
                player.stop(ifPlaying: text)
            } else {
                player.speak(text)
            }
        } label: {
            Image(systemName: isPlayingThis ? "stop.circle.fill" : "speaker.wave.2.fill")
        }
        .accessibilityLabel(Text(isPlayingThis ? "停止朗读" : "朗读"))
    }
}
