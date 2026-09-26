# 06: Hearing a Word, and hearing an Article

**What to build:** Sound. A tapped **Word** can be heard, each **Daily New Words** row can be heard, and a whole **Article** can be played.

The **Goal** is to hold real conversations without a translation app, and that includes knowing how a word actually sounds. Today the app only ever shows pinyin, which is a description of a sound rather than the sound.

On-device speech, so nothing is fetched and nothing is bundled: no audio files, no network, no change to how the app works with weak internet ([ADR 0001](../../../docs/adr/0001-native-swift-app-first.md)).

**Blocked by:** None (can start immediately)

**Status:** ready-for-human (the checks left need real audio hardware)

## The rule

- [x] Speech is Mandarin, chosen explicitly rather than taken from the phone's language, so it reads Chinese as Chinese whichever language the app is showing
- [x] Any word can be spoken, including the HSK 1–3 words and names the app does not measure: hearing something is not a measurement and records nothing
- [x] Playing a Word or an Article records nothing at all — no **Lookup**, no **Clean Sighting**, no minutes. Not merely tested but structural: `SpeechPlayer` takes no `ModelContext` and holds no reference to `Article`, `WordLookup` or `WordProgress`, so there is nothing in it capable of writing any of the three
- [x] Starting a new sound stops the one playing rather than talking over it
- [x] Leaving a screen stops **that screen's own sound**, and only that — never a different screen's, playing underneath it (see Comments: the first version of this got that wrong)

## The screen

- [x] A speaker beside the tapped word on `WordLookupSheet` — placed by the word itself rather than only by the pinyin, since pinyin doesn't exist for an unmeasured word and "any word can be spoken" has to include those too
- [x] A speaker on each Daily New Words row — the moment a student most needs to hear a word is before deciding 认识 or 不认识
- [x] One play control for the whole Article, tucked into the existing meta line rather than the body: the reading screen's rule is "no chips, no meta, no controls in the way of the text", and a speaker on every sentence would break it outright
- [x] Every control has its spoken label for VoiceOver ("朗读" / "停止朗读"), and none of them is only an icon to a screen reader

## Tests

Sound itself is checked by ear, not by assertion. What can be pinned:

- [x] The Mandarin voice is asked for by its own fixed language code, never inherited from `LanguageSetting` or `Locale.current`
- [x] Any Chinese text gets a voice, including a Word the app doesn't measure
- [x] `stop(ifPlaying:)` leaves audio alone when it is told the wrong name, and stops it when told the right one — the guard that makes "leaving a screen" safe once more than one screen can be playing at once

**Not written, and why:** "Playing a Word writes no Lookup and no progress row" isn't a database test here, because there is no database reference in `SpeechPlayer` for such a test to check against — the guarantee is in the type's shape, not in an assertion that happened to find nothing this run.

## Glossary

Nothing new: hearing a Word doesn't touch **Known**, **Clean Sighting** or any other measured term, so nothing here needed a name in `CONTEXT.md`.

## Left for the iPhone

- [ ] Listen to ten Words and judge whether the voice is good enough to learn from. If it is not, say so plainly rather than shipping it
- [ ] Play a whole Article and check the pace is usable for reading along
- [ ] Check the Article control does not get in the way of the text
- [ ] Check sound stops when the screen is left, and when the phone is locked
- [ ] Play an Article, then tap a Word to open its sheet without touching the sheet's own speaker, and confirm the Article keeps narrating underneath — this is exactly the case the review caught and the fix targets
- [ ] Judge whether placing the Word sheet's speaker "by the word" rather than strictly "beside the pinyin" reads as intentional or as a layout mistake

## Comments

Built with the parts that could be pinned tested first. Whole suite green at **236 tests**, up from 231.

`/code-review` found two real bugs, both in the part of this ticket that isn't "checked by ear" — the bookkeeping around what's currently playing.

1. **A race that fired almost every time, not rarely.** `speak(_:)` cancels whatever was playing before starting the new sound. That cancellation's own `didCancel` callback is only *scheduled* onto the actor, not run inline — so by the time it actually runs, `speak(_:)` has already returned having set `currentText` to the *new* text. The stale callback then cleared that new value, leaving the button showing "play" while the Word or Article was still audibly speaking. Fixed by having both `didFinish` and `didCancel` check the utterance's own text against `currentText` before clearing it, so a cancellation for the *old* utterance can never clear the *new* one's state.
2. **"Leaving the screen stops the sound" was true for the wrong sound.** `SpeechPlayer` is one player behind every speaker in the app, so an unconditional `stop()` on `onDisappear` silenced whatever was playing regardless of which screen started it — dismissing a Word sheet opened while an Article was narrating underneath it cut the Article off, even though the sheet itself had never played anything. Fixed with `stop(ifPlaying:)`, which only stops if the text it's given is what's actually still playing, used at all three call sites (`WordLookupSheet` checks its own word, `ArticleReaderView` its own full text, `ReadingView` any of its own ten daily words).

Fixing (2) needed a way to construct a `SpeechPlayer` other than `.shared`, so the guard's tests wouldn't share state with each other or with anything else touching the singleton. `init()` was opened from `private` to internal for exactly that; the singleton is still what every screen actually uses.

Not seen running: anything on the phone — this ticket is unusually dependent on hearing it and on nested-screen navigation, both of which are exactly what the "Left for the iPhone" checks now call out first.
