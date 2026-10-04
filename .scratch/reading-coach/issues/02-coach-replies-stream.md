# 13: 读伴 replies as it writes them

**What to build:** The **Reading Coach** streams its reply as it is written, instead of returning one whole block when it is done. Each piece arrives in a live bubble; the final whole is saved as the **Coach Message** when the stream ends.

Why streaming is worth the complication: a blank sheet with a spinner for ten seconds reads as broken, and seeing the Coach think out loud is how the student knows it is answering their question and not somebody else's.

**Blocked by:** Ticket 12.

**Status:** ready-for-human (needs the student's own API key to watch run end to end)

## The rule

- [x] `CoachClient.streamReply(to:)` returns an `AsyncThrowingStream<String, Error>`; each yielded value is one piece of the reply, joined in order
- [x] `AnthropicCoachClient` posts the Messages API with `stream: true`, reads Server-Sent Events off `URLSession.bytes(for:).lines`, and yields the text of each `content_block_delta`
- [x] Every other SSE event (`message_start`, `content_block_start`, `ping`, `message_stop`) is ignored
- [x] A `data:` line that isn't valid JSON reads as nil, not as a thrown parser error — the Coach does not die on one weird line
- [x] `CoachLibrary.ask(…, onChunk:)` forwards each chunk to the sheet and saves one `CoachMessage` with the joined whole when the stream ends
- [x] A stream that ends with no text at all throws `malformedResponse` and the student's turn is rolled back, the same as any other failure
- [x] A cancellation (sheet closed mid-stream) cancels the URLSession task; the user row rolls back and nothing is saved
- [x] The sheet shows a live bubble with a cursor marker while the reply streams in, and the live bubble clears only after the saved message has been reloaded, so there is no flicker between the two

## Comments

- Full suite: 295 passing, up from 290.
- Four new tests on the SSE parser (`CoachStreamingTests`) and one new behaviour test on `CoachLibrary` for chunks arriving in order.
- `URLSession.bytes(for:).lines` is the iOS 15+ Foundation API for line-by-line reads of a streamed response. No library.
- Watch it end to end: paste a long question in 问, see 读伴 start replying inside a second or so, text filling in.
