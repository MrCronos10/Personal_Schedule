# 07: Photograph an Article

**What to build:** Importing an **Article** by camera, or from a photo already taken. Typing or pasting a menu, a sign or a page of a textbook by hand is the reason the reading list stays empty, and an empty 阅读 tab cannot be interesting however good the reader is.

Text recognition on the device, so this needs no network. A bundled library of ready-made Articles was considered instead and dropped: [ADR 0005](../../../docs/adr/0005-levels-measure-a-fixed-list-and-never-gate-reading.md) is built on the student reading the real Chinese in front of them, and this gets more of that, sooner.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

## The rule

- [ ] Recognition is Simplified Chinese, asked for explicitly
- [ ] Recognised text always lands in the same editable field the student already types into, and is never saved straight from the camera. Menus have odd fonts and signs have glare, and a **Word** banked on a misrecognised character is the "wrong reading is worse than none" mistake `Vocabulary/SOURCE.md` already argues against — reached from a new direction
- [ ] One image per Article. Stitching several photos of a textbook page together is its own feature if it is ever needed, not a one-line add-on
- [ ] Everything else about import is unchanged: the title still comes from the first line, the **Source** is still optional free text in the student's own words, and the Article is still archived, never deleted
- [ ] Recognising nothing is an ordinary answer, not an error: the field opens empty and the student can type

## The screen

- [ ] The import sheet offers taking a photo and choosing one from Photos, beside the existing paste
- [ ] Pasting still works exactly as it does now, and is still the way to bring in text already on the phone
- [ ] Refusing camera or photo permission leaves paste working and says what happened, rather than a dead button
- [ ] The camera and photo permission reasons are written in both languages

## Tests

Recognition itself needs a camera and a real image, so it is checked by hand. What can be pinned:

- [ ] Recognised text is handed to the import flow as editable text, not saved directly
- [ ] An Article made this way is the same kind of Article as a pasted one: title from the first line, optional Source, archivable
- [ ] Empty recognition produces an empty field, not a saved Article and not an error

## Glossary

- [ ] **Article** in `CONTEXT.md` widens to "pasted or photographed" once this is true — held back until then

## Left for the iPhone

- [ ] Photograph a real 菜单 and a real 路牌 and see how much comes back right
- [ ] Fix a misread character in the field before saving, and confirm what saves is what was fixed
- [ ] Import a screenshot of a 微信 article from Photos
- [ ] Deny permission on purpose and check the sheet still makes sense
