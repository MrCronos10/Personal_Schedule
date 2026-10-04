import Testing
@testable import PersonalSchedule

/// How a Note is laid out as an index card: its first line is the card's title, the rest its body,
/// and the stack leans a little each way so it reads as a pile of paper.
struct NoteCardTests {
    @Test func theFirstLineIsTheTitleAndTheRestIsTheBody() {
        let note = NoteCardStyle.split("新词：厕所\n发音 cè suǒ\n在茶馆问的")
        #expect(note.title == "新词：厕所")
        #expect(note.body == "发音 cè suǒ\n在茶馆问的")
    }

    @Test func aOneLineNoteIsAllTitle() {
        let note = NoteCardStyle.split("今天的新词是导游")
        #expect(note.title == "今天的新词是导游")
        #expect(note.body.isEmpty)
    }

    @Test func leadingBlankLinesAndSpacesAreSkipped() {
        let note = NoteCardStyle.split("\n  \n  标题  \n正文")
        #expect(note.title == "标题")
        #expect(note.body == "正文")
    }

    @Test func nothingWrittenIsAnEmptyCard() {
        #expect(NoteCardStyle.split("").title.isEmpty)
        #expect(NoteCardStyle.split("   \n ").body.isEmpty)
    }

    @Test func cardsLeanAlternatelyByTwoDegrees() {
        #expect(NoteCardStyle.tilt(at: 0) == -2)
        #expect(NoteCardStyle.tilt(at: 1) == 2)
        #expect(NoteCardStyle.tilt(at: 2) == -2)
    }
}
