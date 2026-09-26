import Foundation
import Testing
@testable import PersonalSchedule

/// Hearing a Word or an Article, entirely on the device (ADR 0001). Sound itself is checked by ear;
/// what can be pinned is which voice is asked for.
///
/// `SpeechPlayer` takes no `ModelContext` at all, so "playing records no Lookup, no Clean Sighting
/// and no Reading Session minutes" is not a runtime assertion here — there is no store reference for
/// it to have written to in the first place, which is a stronger guarantee than a test that merely
/// found nothing this time.
struct SpeechPlayerTests {
    @Test func theVoiceIsAskedForByItsOwnLanguageCode() throws {
        let utterance = SpeechPlayer.utterance(for: "你好")
        #expect(utterance.voice?.language == SpeechPlayer.voiceLanguageCode)
    }

    /// Fixed at "zh-CN" regardless of what the app's own language setting or the phone's locale say —
    /// the two are different questions, and this one is never asked of either.
    @Test func theVoiceLanguageCodeIsFixedToMandarin() throws {
        #expect(SpeechPlayer.voiceLanguageCode == "zh-CN")
    }

    /// Any Chinese text can be spoken, not only the HSK 4/5 Words the app measures: hearing something
    /// is not a measurement (ADR 0005).
    @Test func anUnmeasuredWordStillGetsAVoice() throws {
        let utterance = SpeechPlayer.utterance(for: "很")
        #expect(utterance.voice?.language == SpeechPlayer.voiceLanguageCode)
    }

    // MARK: - Leaving a screen must not stop someone else's sound

    /// A fresh player, not `.shared`: these tests read and change `currentText`, and sharing the
    /// singleton would let them interfere with each other or with anything else touching it.
    @MainActor
    private func player() -> SpeechPlayer { SpeechPlayer() }

    /// `stop(ifPlaying:)` is what a screen's `onDisappear` calls. Naming the wrong text is exactly
    /// what happens when an Article is narrating underneath a Word sheet that never played anything
    /// itself: the sheet closing must not silence the Article.
    @MainActor
    @Test func stopIfPlayingLeavesUnrelatedAudioAlone() throws {
        let player = player()
        player.speak("文章全文")
        #expect(player.currentText == "文章全文")

        player.stop(ifPlaying: "厕所")
        #expect(player.currentText == "文章全文")
    }

    @MainActor
    @Test func stopIfPlayingStopsWhatItNames() throws {
        let player = player()
        player.speak("厕所")
        player.stop(ifPlaying: "厕所")
        #expect(player.currentText == nil)
    }
}
