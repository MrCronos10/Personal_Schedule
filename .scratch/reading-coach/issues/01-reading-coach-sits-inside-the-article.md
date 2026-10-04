# 12: 问读伴 — a Reading Coach inside the Article

**What to build:** A chat sheet opened from inside an **Article** that answers the student's questions about *that* Article. One **Coach Session** per Article: a thread of **Coach Messages**, each with a **Coach Language** picked per message (中/EN, 中文 only, or English only). Uses claude-sonnet-5-5 through the Anthropic Messages API; the student's API key lives in Keychain.

Why the Coach never writes a Known, a Clean Sighting, a Topic Known or a streak: [ADR 0008](../../../docs/adr/0008-reading-coach-is-a-side-helper-not-homework.md). Why the Coach is inside the reader and nowhere else: the same ADR.

**Blocked by:** None.

**Status:** ready-for-human (the taps left are iPhone-only; a real reply needs the student's own key)

## The rule

- [x] 问 is a button in the Article reader's header; opening it opens the **Coach Session** for *that* Article
- [x] Each message carries its **Coach Language**: both / Chinese only / English only, picked per message
- [x] The system prompt carries the Article's title, source and text, the **Known** HSK Words inside this Article (not the whole Known set, which would be 1,500 words of noise), and the **Topic Words** inside this Article
- [x] The whole thread is sent each time, so the Coach answers follow-up questions with the earlier replies still in mind
- [x] An empty question is refused; a reply that fails to arrive rolls back the student's turn so the thread never carries an unanswered question
- [x] Clearing a thread removes only that Article's messages
- [x] The Coach never writes a `WordProgress`, `CleanSighting`, `WordLookup` or `TopicWordProgress` row — the test `theCoachNeverWritesAKnownOrASightingOrALookup` is the guard
- [x] The system prompt forbids streaks, due dates, "practice more", and recommending other apps or flashcards
- [x] The API key is stored in Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`), never in UserDefaults; the Settings pane 保存 / 清除 writes and wipes

## What is not in this ticket

- A proxy for the API key. ADR 0008 says why: a Vercel Function is the right long-term answer; shipping it in this ticket would need the student to set up a Vercel account first. The `CoachClient` protocol is the seam a `ProxyCoachClient` slots into later.
- Streaming the reply as it arrives. The whole reply is shown at once. Can be added later without changing the library.
- The three other jobs the prototype showed (Word Tutor, Conversation Partner, Fertilizer Research Buddy). Each is its own ticket with its own prompt and placement.

## Comments

- `/code-review` was done against the diff and the one real finding — a thread sort that read messages out of order — was folded back in before this file was finalised.
- The 问 sheet and the Settings field were built; the student taps through on the phone (AGENTS.md).
- Full suite passes. New tests cover: saving an exchange, an empty question, a failed reply rolling back, clearing one Article's thread, the whole thread travelling with each send, the Article text and Topic Words reaching the Coach, only Known-in-this-Article words being listed, the Coach never writing a Known / Sighting / Lookup / Topic Known, and the system prompt carrying the house rules.
- Xcode's string catalog extraction has not been run yet; the next IDE build will pull the new Chinese strings into `Localizable.xcstrings`, where the student can translate them.
