# The Reading Coach runs on Qwen and sends a short window

**Status:** accepted by the student, 2026-10-24. Supersedes the model and provider choice in
[ADR 0008](0008-reading-coach-is-a-side-helper-not-homework.md); its house rules stand unchanged.

The Coach sent everything on every message: the house rules, the whole Article, the Known and
Topic Words, and every turn of the **Coach Session** since it began. Most of that is identical
from one message to the next, and the history grows without limit. The student pays for the app
themselves and wants the Coach to cost as little as it can without becoming a worse Coach.

## Decision

- **Memory stays inside one Coach Session.** Nothing about the student is carried from one
  Article to the next. A profile of "words you keep asking about" would add tokens, not save
  them, and drifts towards the review ADR 0004 rejected.
- **Provider: Alibaba Model Studio, International (Singapore), model `qwen3.7-flash`.** Reported at
  about $0.03 / $0.13 per million input / output tokens for prompts under 32K, against Sonnet
  5.5's several dollars. Strong in Chinese. Called through the OpenAI-compatible
  `/compatible-mode/v1/chat/completions` endpoint with `stream: true`. The model id is one
  constant; Alibaba renames Flash models roughly every quarter.
- **Only the last 6 turns of history are sent**, plus the new question. Older Coach Messages stay
  saved and on screen; they are just not sent. The Article is always in the prompt, so the Coach
  never loses the subject, only old chat. One constant, `historyLimit`.
- **The whole Article is sent every time**, near the top of the prompt, so the provider's cache
  can reuse it. Cutting to one paragraph would need a new UI step and make the Coach worse to
  save fractions of a cent.
- **Implicit caching, no cache code.** Model Studio caches a repeated prompt prefix automatically
  and bills a hit at 20% of input. Explicit `cache_control` bills a hit at 10% but charges 125% to
  write the cache, so a one-question Session costs more. The difference is hundredths of a cent.
- **The prompt order is fixed so its start never changes within a Session**: house rules →
  Article → Known Words / Topic Words → last 6 turns → the new question with its **Coach
  Language**. The language moves out of the system prompt, because it is picked per message and
  a change there would break the cache for everything after it.
- **`maxTokens = 1000`.** The student's choice. A full-length reply costs about $0.00013; the
  prompt's "keep answers short" keeps ordinary replies short.
- **Token usage goes to the debug log only.** The request sets `stream_options.include_usage`; the
  client logs input, cached and output tokens with `os_log` in debug builds. No count on any
  screen and no new field in the database (ADR 0008: no "messages today").
- **Anthropic is removed**, not kept as a hidden fallback. `AnthropicCoachClient` is deleted and the
  Keychain slot holds the Qwen key. The `CoachClient` protocol is the seam to bring a provider
  back; git history keeps the old client.

## Considered Options

- **Stay on Anthropic, switch to Haiku, add `cache_control`.** Least code. Rejected on price; the
  student chose Qwen.
- **Support both providers with a picker.** Rejected: two clients, two keys, two sets of tests for
  a one-student app.
- **Summarise old turns.** Every summary is an extra paid request to save a few hundred tokens,
  and it can lose the detail "what does *this* mean" needs.
- **Send no history.** Cheapest, but breaks follow-up questions.
- **Keep `maxTokens` at 600 or lower it.** The student wanted room for longer explanations.
- **Show cost in Settings.** Breaks ADR 0008.

## Consequences

- Estimated cost: about $0.0001–0.0002 per question; a reported 1M-token free quota for 90 days
  may cover months of use. Prices come from third-party trackers, not Alibaba's own page.
- Answer quality in Chinese pedagogy is unproven against Sonnet. If it disappoints, `qwen3.8-flash`
  (about 5× the price, still well under a tenth of a cent a message) is a one-line change.
- Settings, the Coach's error text and `Localizable.xcstrings` change wording from Anthropic to Qwen.
- A student who had an Anthropic key saved must paste a Qwen key; the old one is not usable.
