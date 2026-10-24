# 26: 读伴 moves to Qwen and sends a short window

**What to build:** The **Reading Coach** talks to Alibaba's `qwen3.7-flash` instead of Anthropic, and stops re-sending what it doesn't need: only the last 6 turns of the **Coach Session** go with each question, in a fixed order that lets the provider cache the unchanging start. See [ADR 0011](../../../docs/adr/0011-reading-coach-runs-on-qwen-and-sends-a-short-window.md).

Why: the student pays for the Coach themselves. Every message currently re-sends the whole thread, and history grows without limit.

**Blocked by:** Ticket 13 (streaming), done.

**Status:** ready-for-human (needs the student's Qwen key on the iPhone to watch it run)

## The rule

Library (`CoachLibrary`, `CoachPromptBuilder`), test-first:

- [x] `buildPrompt` sends at most `historyLimit = 6` earlier turns, the most recent ones, oldest first, plus the new question
- [x] A Session shorter than the limit sends every earlier turn, unchanged from today
- [x] Older Coach Messages are still returned by `messages(for:)` — trimming the prompt never deletes or hides a saved message
- [x] The system prompt no longer contains the **Coach Language** line; switching language between two messages leaves the system prompt byte-for-byte identical
- [x] The language instruction travels with the new question instead (sent with it, not saved into the Coach Message text)
- [x] The system prompt order is house rules → Article → Known Words / Topic Words, and holds no per-message value (no date, no language)

Client (`QwenCoachClient`, replacing `AnthropicCoachClient`):

- [x] POSTs `https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions` with `Authorization: Bearer <key>`, `model: "qwen3.7-flash"`, `max_tokens: 1000`, `stream: true`, `stream_options: {"include_usage": true}`, `enable_thinking: false`
- [x] The system prompt is sent as the first message with `role: "system"`, then the turns
- [x] The SSE parser yields `choices[0].delta.content`; ignores lines without content, the usage-only chunk, and `data: [DONE]`; reads invalid JSON as nil, not a thrown error (same guarantees as ticket 13)
- [x] The usage chunk's prompt, cached and completion tokens are logged with `os_log` in debug builds only; nothing is shown or saved
- [ ] Missing key, non-2xx status and an empty stream map to the existing `CoachClientError` cases (the code path is unchanged from ticket 13, but no test covers it)
- [x] `AnthropicCoachClient` and its tests are deleted; `CoachStreamingTests` tests the Qwen parser

Key and copy:

- [x] `CoachSecrets.service` names the Qwen key; an old Anthropic key is not read as a Qwen key, and saving or clearing the key wipes it
- [x] Settings, the dock's no-key line and the error text say Qwen / 通义千问 instead of Anthropic, the placeholder is `sk-…`, and every new string has its English in `Localizable.xcstrings`

By hand, on the student's iPhone:

- [ ] Paste the Qwen key in 设置, ask a question in an Article, see the reply stream in
- [ ] Ask two questions on one Article within a few minutes; the Xcode console shows cached tokens on the second
- [ ] Ask more than 3 questions on one Article; a follow-up like "这个呢？" about the last reply still makes sense

## Comments

- Full suite: 414 passing in 38 suites, up from 411 before the review fixes (295 at ticket 13).
- Library, test-first: only the last 6 earlier turns travel (`historyLimit`), a saved message is never hidden (passed when written, kept as a guard), a window never opens on a Coach reply, switching language leaves the system prompt identical, the language line rides only on the new question, and the system prompt order is rules → Article → word lists (already true when written, kept as a guard).
- Client: `QwenCoachClient` replaces `AnthropicCoachClient`. Its parser and request body are tested without the network (`CoachStreamingTests`); token usage is logged with `os_log` in debug builds only.
- Keychain: `CoachSecretsTests` runs against the simulator's real Keychain and restores whatever key was there.
- `/code-review` found eight things. Fixed: `enable_thinking: false` is now sent (hidden reasoning could spend the reply budget); saving or clearing the key wipes the old Anthropic key; an orphan question can no longer make the window open on a reply; each stream line is decoded once; the Keychain test now uses the real Keychain. Not changed: the Known list in the system prompt changes only after 读完 and sits after the Article, so the cached start still matches; the "language line skipped if the last turn isn't the student's" case can't happen, since `buildPrompt` always ends with the question.
- The first full-suite run after the Keychain fix ended "TEST FAILED" after only 133 tests, with no test named as failing. Two runs since are clean. Cause not found.
- Not seen running: no real request has been sent from the app. The student's own curl confirmed the endpoint and model name. Whether `qwen3.7-flash` accepts `enable_thinking` without complaint is first seen on the phone.
