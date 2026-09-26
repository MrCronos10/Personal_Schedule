# 07: Photograph an Article

**What to build:** Importing an **Article** by camera, or from a photo already taken. Typing or pasting a menu, a sign or a page of a textbook by hand is the reason the reading list stays empty, and an empty 阅读 tab cannot be interesting however good the reader is.

Text recognition on the device, so this needs no network. A bundled library of ready-made Articles was considered instead and dropped: [ADR 0005](../../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md) is built on the student reading the real Chinese in front of them, and this gets more of that, sooner.

**Blocked by:** None (can start immediately)

**Status:** ready-for-human (the checks left need a camera and real photos)

## The rule

- [x] Recognition is Simplified Chinese, asked for explicitly
- [x] Recognised text always lands in the same editable field the student already types into, and is never saved straight from the camera. Menus have odd fonts and signs have glare, and a **Word** banked on a misrecognised character is the "wrong reading is worse than none" mistake `Vocabulary/SOURCE.md` already argues against — reached from a new direction
- [x] One image per Article. Stitching several photos of a textbook page together is its own feature if it is ever needed, not a one-line add-on
- [x] Everything else about import is unchanged: the title still comes from the first line, the **Source** is still optional free text in the student's own words, and the Article is still archived, never deleted — the OCR path reuses `ArticleLibrary.add` exactly, no second creation path
- [x] Recognising nothing is an ordinary answer, not an error: the field opens empty and the student can type. Vision *failing to run at all* is not the same event and is not folded into it — see Comments

## The screen

- [x] The import sheet offers taking a photo and choosing one from Photos, beside the existing paste
- [x] Pasting still works exactly as it does now, and is still the way to bring in text already on the phone
- [x] Refusing camera permission leaves paste working and says what happened, rather than a dead button. Photos needs no permission at all — `PhotosPicker` runs out of process and never gives the app broader access than the one photo chosen
- [x] The camera permission reason and every new button/error string are written in both languages

## Tests

Recognition itself needs a camera and a real image, so it is checked by hand. What can be pinned is what happens to Vision's results once it has them, not the recognition itself:

- [x] Vision's lines are ordered top-to-bottom by vertical position, since it doesn't promise reading order
- [x] A whitespace-only line is dropped
- [x] No lines produce an empty string, not an error
- [x] Each line is trimmed before joining

**Not written as database tests, and why:** "recognised text is handed to the import flow as editable text, not saved directly" and "an Article made this way is the same kind as a pasted one" are both architectural guarantees rather than runtime ones — `TextRecognizer` takes no `ModelContext` and never calls `ArticleLibrary`, and the OCR path calls the exact same `ArticleLibrary.add` the paste path already uses and `ArticleLibraryTests` already covers. There is no second path for a test to find behaving differently.

## Glossary

- [x] **Article** in `CONTEXT.md` widens to "pasted or photographed" now that it is true

## Left for the iPhone

- [ ] Photograph a real 菜单 and a real 路牌 and see how much comes back right
- [ ] Fix a misread character in the field before saving, and confirm what saves is what was fixed
- [ ] Import a screenshot of a 微信 article from Photos
- [ ] Deny camera permission on purpose and check the sheet still makes sense, and that paste still works
- [ ] Judge whether replacing the whole draft on each photo (rather than appending) is the right call — noted as a judgement made without a way to test it, in Comments

## Comments

Built test-first where the rule was pure. Whole suite green at **249 tests**, up from 245.

`/code-review` found one real bug, and it's the same shape as several from earlier tickets in this round: a `try?` collapsing two different events into one. `recognizeAndFill` used `(try? await TextRecognizer.recognizeText(in: image)) ?? ""` to fill the text field. That's correct when Vision runs and genuinely finds nothing — an empty string is the honest answer. But it's also what happens when Vision *fails to run at all*, which `try?` cannot tell apart from the first case, and which silently wiped out anything the student had already typed with no message shown at all — unlike the sibling failure path a few lines above it, for a photo that couldn't even be loaded, which does show one. Fixed with an explicit `do`/`catch`: success (empty or not) fills the field and focuses it; failure leaves the draft untouched and says so.

Design judgement made without a way to test it: a new photo replaces the whole draft rather than appending to it. The ticket didn't specify this, and I reasoned it from "one image per Article" — a photo is a whole attempt at getting text in, the same way pasting overwrites a half-typed paste, not a second source added alongside the first. Flagged for the phone rather than assumed settled.

Not seen running: anything on the phone at all. This ticket has the least automated coverage of the round by necessity — the Simulator has no camera, and the tests that exist are deliberately scoped to the one part of the pipeline that doesn't need one.
