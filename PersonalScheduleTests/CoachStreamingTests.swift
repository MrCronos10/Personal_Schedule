import Foundation
import Testing
@testable import PersonalSchedule

/// Pulling one text piece out of a Server-Sent Event line Qwen streams back through Alibaba's
/// OpenAI-compatible endpoint. Pure, so no network and no URLSession is involved: the test gives
/// the parser one line at a time and asserts what came out. See ADR 0011.
struct CoachStreamingTests {
    @Test func aContentDeltaReturnsItsText() throws {
        let payload = #"{"choices":[{"index":0,"delta":{"content":"你好"},"finish_reason":null}]}"#
        #expect(QwenCoachClient.textDelta(from: payload) == "你好")
    }

    @Test func anEmptyContentDeltaStillComesBackAsItsEmptyString() throws {
        // The first chunk often carries the role and an empty content; it is not malformed and the
        // client skips it on emptiness, not on nil.
        let payload = #"{"choices":[{"index":0,"delta":{"role":"assistant","content":""}}]}"#
        #expect(QwenCoachClient.textDelta(from: payload) == "")
    }

    @Test func everyOtherLineReturnsNil() throws {
        for payload in [
            #"{"choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}"#,
            #"{"choices":[],"usage":{"prompt_tokens":3000,"completion_tokens":120,"total_tokens":3120}}"#,
            "[DONE]",
        ] {
            #expect(QwenCoachClient.textDelta(from: payload) == nil, "\(payload) should not read as text")
        }
    }

    @Test func aMalformedLineComesBackAsNil() throws {
        #expect(QwenCoachClient.textDelta(from: "not json") == nil)
    }

    @Test func theUsageChunkReadsAsInputCachedAndOutputTokens() throws {
        let payload = #"{"choices":[],"usage":{"prompt_tokens":3000,"completion_tokens":120,"total_tokens":3120,"prompt_tokens_details":{"cached_tokens":2400}}}"#
        let usage = try #require(QwenCoachClient.usage(from: payload))
        #expect(usage == CoachUsage(inputTokens: 3000, cachedTokens: 2400, outputTokens: 120))
    }

    @Test func aUsageChunkWithoutCacheDetailsReadsAsZeroCached() throws {
        let payload = #"{"choices":[],"usage":{"prompt_tokens":3000,"completion_tokens":120,"total_tokens":3120}}"#
        #expect(QwenCoachClient.usage(from: payload)?.cachedTokens == 0)
    }

    @Test func theRequestAsksForAShortStreamedReplyWithUsageAndNoThinking() throws {
        // Hidden reasoning tokens are billed and can spend the whole max_tokens budget before any
        // reply text arrives, so thinking is switched off in writing rather than left to a default.
        let prompt = CoachPrompt(history: [CoachTurn(role: .user, text: "问")],
                                 article: ArticleView(title: "t", source: nil, text: "x"),
                                 knownInArticle: [], topicWordsInArticle: [], language: .both)
        let data = try QwenCoachClient.requestBody(for: prompt)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["model"] as? String == "qwen3.7-flash")
        #expect(json["max_tokens"] as? Int == 1000)
        #expect(json["stream"] as? Bool == true)
        #expect(json["enable_thinking"] as? Bool == false)
        let streamOptions = json["stream_options"] as? [String: Any]
        #expect(streamOptions?["include_usage"] as? Bool == true)
        let messages = try #require(json["messages"] as? [[String: Any]])
        #expect(messages.first?["role"] as? String == "system")
    }

    @Test func aTextChunkHasNoUsage() throws {
        let payload = #"{"choices":[{"index":0,"delta":{"content":"你好"}}]}"#
        #expect(QwenCoachClient.usage(from: payload) == nil)
    }
}
