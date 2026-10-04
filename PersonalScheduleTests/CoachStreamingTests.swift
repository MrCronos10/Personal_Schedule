import Foundation
import Testing
@testable import PersonalSchedule

/// Pulling one text piece out of a Server-Sent Event line Anthropic streams back. Pure, so no
/// network and no URLSession is involved: the test gives the parser one line at a time and asserts
/// what came out. See ADR 0008.
struct CoachStreamingTests {
    @Test func aTextDeltaReturnsItsText() throws {
        let payload = #"{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"你好"}}"#
        #expect(AnthropicCoachClient.textDelta(from: payload) == "你好")
    }

    @Test func anEmptyTextDeltaStillComesBackAsItsEmptyString() throws {
        // Anthropic sometimes emits an empty text delta on content_block_start; it is not a
        // malformed event and the library skips it on emptiness, not on nil.
        let payload = #"{"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":""}}"#
        #expect(AnthropicCoachClient.textDelta(from: payload) == "")
    }

    @Test func everyOtherEventReturnsNil() throws {
        for payload in [
            #"{"type":"message_start","message":{"id":"m","type":"message"}}"#,
            #"{"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}"#,
            #"{"type":"content_block_stop","index":0}"#,
            #"{"type":"message_stop"}"#,
            #"{"type":"ping"}"#,
        ] {
            #expect(AnthropicCoachClient.textDelta(from: payload) == nil, "\(payload) should not read as a text delta")
        }
    }

    @Test func aMalformedLineComesBackAsNil() throws {
        #expect(AnthropicCoachClient.textDelta(from: "not json") == nil)
    }
}
