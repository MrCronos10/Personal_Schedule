# The Reading Coach is a side helper, not homework

The student is reading real Chinese writing — a 微信 post, a menu, a page of a
fertilizer handbook — and sometimes gets stuck. The app adds a **Reading
Coach**: 问读伴, a small chat sheet opened from inside an **Article** that
answers questions about *that* Article. It uses the Anthropic Messages API
with claude-sonnet-5-5.

[ADR 0004](0004-known-is-earned-by-reading-not-by-review.md) said the app has
no streaks, no SRS queue, nothing due. The Reading Coach must not break that
line, so this ADR writes the Coach's house rules down.

## House rules the Coach never breaks

- **Never marks a word Known, a Clean Sighting, a Lookup, or a Topic Known.**
  Those live in `WordProgress`, `CleanSighting`, `WordLookup` and
  `TopicWordProgress`. `CoachLibrary` is read-only against all four; the
  matching test `theCoachNeverWritesAKnownOrASightingOrALookup` fails first if
  that is ever crossed.
- **Never counts messages, shows a streak, or says the student is "due".**
  The system prompt forbids these phrases in writing. There is no "messages
  today" number anywhere on the Settings screen.
- **Never recommends other apps, decks or flashcards.** The system prompt
  forbids this.
- **Lives only inside an Article.** The 问 button is in the reader's header,
  one line above the text. There is no new tab, no floating 问, no 问 on every
  Word. If the student leaves the Article, the Coach is gone — the Article is
  the subject.

## Why Sonnet 5.5

- **Haiku 4.5** is faster and cheaper, but Chinese pedagogy — reading the
  nuance of a 微信 post, catching that 篇 is a measure word for articles, not
  just "paper" — rewards the stronger model. The Coach only runs when the
  student asks, so a slightly slower reply is not a flashcard-queue problem.
- **Opus 5.5** would answer better still, but costs about five times Sonnet
  for a change the student will mostly not notice in short, specific replies.
- **Sonnet 5.5** is the model id `claude-sonnet-5-5`. One `AnthropicCoachClient`
  constant, so a swap later is a one-line edit.

## Where the API key lives, and the proxy that is coming later

This ticket does not ship a Vercel Function or any proxy. The student is the
only user, so the key lives on the phone — in **Keychain**, device-only
(`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`), never in `UserDefaults`,
never backed up to iCloud. The Settings pane has a secure field for pasting
it, 保存 to write, 清除 to wipe.

The right long-term answer is a small proxy that holds the key and that the
app talks to over HTTPS. Doing it in this ticket would need the student to
have a Vercel account and a deployed function before the Coach does anything,
which is a lot of yak-shaving for a one-student app. The `AnthropicCoachClient`
and `CoachClient` protocol are a clean seam: a `ProxyCoachClient` that posts
to a different URL with a different header slots in without changing the
library or the sheet.

## Considered Options

- **A new tab 问.** Easy to find, easy to drift into daily use that starts to
  feel like homework. Rejected on ADR 0004 grounds: a permanent place with its
  own number next to the HSK Levels is the opposite of "a by-product of
  reading." The 问 button inside the reader keeps the Article as home.
- **Long-press any word.** Nicer for a Word Tutor job, but the task picked
  the Reading Coach job (grill-with-docs session), and a Coach that only ever
  has one word of context is a worse Coach.
- **A floating 问 everywhere.** Pervasive AI-slop, exactly the look the Stitch
  design guard rejects (`Theme.swift`).
- **Haiku 4.5 as the default model, Sonnet as a premium toggle.** Rejected:
  one student, one model, and the simpler setting is the one that stays right
  when the student is tired.
- **Ship the proxy in this ticket.** Rejected on scope — the proxy is its own
  ticket with its own tests (billed-request limit, no-API-key error path,
  Vercel OIDC). The seam is kept so this is a drop-in later.

## Consequences

- The schema grows by one table, `CoachMessage`, scoped to one Article.
- The reader gets one new control, the 问 button, right of the source line.
- Settings gets a 读伴 section with the SecureField and 保存 / 清除.
- Nothing in the HSK or Topic List pipeline is touched.
- The Coach is only useful when the student is online and has the API key
  set. Both are the student's own problem to notice; the sheet says what the
  blocker is rather than silently refusing to answer.
