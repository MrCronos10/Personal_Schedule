# 06: Hearing a Word, and hearing an Article

**What to build:** Sound. A tapped **Word** can be heard, each **Daily New Words** row can be heard, and a whole **Article** can be played.

The **Goal** is to hold real conversations without a translation app, and that includes knowing how a word actually sounds. Today the app only ever shows pinyin, which is a description of a sound rather than the sound.

On-device speech, so nothing is fetched and nothing is bundled: no audio files, no network, no change to how the app works with weak internet ([ADR 0001](../../../docs/adr/0001-native-swift-app-first.md)).

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

## The rule

- [ ] Speech is Mandarin, chosen explicitly rather than taken from the phone's language, so it reads Chinese as Chinese whichever language the app is showing
- [ ] Any word can be spoken, including the HSK 1–3 words and names the app does not measure: hearing something is not a measurement and records nothing
- [ ] Playing a Word or an Article records nothing at all — no **Lookup**, no **Clean Sighting**, no minutes
- [ ] Starting a new sound stops the one playing rather than talking over it
- [ ] Leaving the screen stops the sound

## The screen

- [ ] A speaker on the tapped-Word sheet, beside the pinyin
- [ ] A speaker on each Daily New Words row — the moment a student most needs to hear a word is before deciding 认识 or 不认识
- [ ] One play control for the whole Article in the reader, and only one: the reading screen's rule is "no chips, no meta, no controls in the way of the text", and a speaker on every sentence would break it outright
- [ ] Every control has its spoken label for VoiceOver, and none of them is only an icon to a screen reader

## Tests

Sound itself is checked by ear, not by assertion. What can be pinned:

- [ ] The Mandarin voice is asked for by name, not inherited from the app's language setting
- [ ] Playing a Word writes no Lookup and no progress row
- [ ] Playing does not touch a **Reading Session**'s minutes

## Left for the iPhone

- [ ] Listen to ten Words and judge whether the voice is good enough to learn from. If it is not, say so plainly rather than shipping it
- [ ] Play a whole Article and check the pace is usable for reading along
- [ ] Check the Article control does not get in the way of the text
- [ ] Check sound stops when the screen is left, and when the phone is locked
