# Personal Schedule

A personal tool for one student's year of study in China. It organises daily life around one goal: speaking Chinese fluently and communicating smoothly with Chinese people.

## Language

**Goal**:
The one aim of the year: to communicate smoothly with Chinese people, holding real conversations without a translation app and handling everyday situations alone. Exam levels are not the Goal. HSK enters the app only as a **Word List**: a ready-made way to decide which words are worth learning next. The student is never preparing for an exam, and the app never mentions one.
_Avoid_: Target, objective, HSK level as a goal

**Action**:
One thing the student plans to do, such as "learn 20 new words". It may have a time or not, and it is ticked off when done.
_Avoid_: Task, to-do, event, item

**Category**:
A group that Actions belong to, such as Chinese or Health, created and named by the student. Every Action belongs to exactly one Category, and its Completions count only there. An activity that spans two Categories is recorded as two Actions.
_Avoid_: Tag, label, type, area

**Weekly Target**:
An optional number of minutes the student aims to reach in one Category each week (Monday to Sunday), such as 7 hours of Chinese. The Progress Tracker compares the week's Completions against it.
_Avoid_: Goal, daily target, quota

**Completion Count**:
What the Progress Tracker shows for a Category with no Weekly Target: how many Completions the week holds, and nothing else. No minutes and no bar, because these are Categories where time doesn't matter, such as 生活. A Category is never left out of the Progress Tracker for having no Weekly Target.
_Avoid_: Tally, score, streak, count-only mode

**Archived Category**:
A Category the student has retired. It can't be chosen for new Actions, but its past Actions and Completions still count in the Progress Tracker, and it can be restored. A Category archived partway through a week still shows that week's Completions, against its Weekly Target if it has one, so work already done is never hidden by a later decision. Categories are archived, never deleted.
_Avoid_: Deleted category, hidden category

**Routine**:
An Action that repeats on set days (every day, weekdays, or chosen days). Each day it appears is ticked off separately, with its own Completion. A day not ticked stays Missed on that day. Changing a Routine affects only today and later days; past days and their Completions stay as they were.
_Avoid_: Recurring task, habit, repeat

**Paused Routine**:
A Routine the student has stopped for now. It doesn't appear on new days, its past days and Completions still count, and it can be resumed later as the same Routine. Each pause is remembered with its start and end dates, and days inside a pause are never Missed. Routines are paused, never deleted.
_Avoid_: Deleted routine, ended routine, archived routine

**One-time Action**:
An Action that happens once. If not ticked by the end of its day, it moves to the next day, and keeps moving until it is ticked or deleted.
_Avoid_: Single task, one-off

**Missed**:
A Routine day, outside any pause, that ended without a Completion, on or after the day the Routine was created. It stays on that day and never moves forward. A Completion can still be added to any past day later, and the day is then no longer Missed. Days before the Routine existed are never Missed, even when its start date reaches further back: the Routine still shows on those days, so a day the student really did can be ticked in, but a day they never planned is not held against them.
_Avoid_: Skipped, failed, overdue

**Timetable**:
The view of a day's Classes and timed Actions, laid out by time.
_Avoid_: Calendar, agenda

**Daily Checklist**:
The view of all of today's Actions, with or without a time, which the student ticks off. Outstanding Actions show before ticked ones, so ticking one off moves it out of the way rather than off the screen.
_Avoid_: To-do list, task list

**Default Minutes**:
An Action's usual length, such as 20 minutes for "learn 20 new words". It fills in a Completion's minutes, and may be empty for Actions where time doesn't matter.
_Avoid_: Duration, estimate, planned time

**Completion**:
The record made when an Action is ticked off: the minutes spent (starting from the Action's Default Minutes, changeable, possibly empty), plus an optional Note. It keeps the Action's title and Category as they were when ticked, and counts toward that Category even if the Action changes later. A Completion with no minutes still counts as done but adds no time to progress.
_Avoid_: Check-in, log entry, done record

**Note**:
Optional free text on a Completion, such as new words met or what was hard.
_Avoid_: Comment, journal, memo

**Notes List**:
The view of all Notes from newest to oldest, searchable, used to review words met in real life.
_Avoid_: Journal, word list, vocabulary

**Evening Check**:
One reminder each evening that shows the day's Actions not yet ticked off and how close each Category is to its Weekly Target.
_Avoid_: Daily summary, nightly reminder, review

**Class**:
A university lesson that repeats every week at a fixed day and time, between a start date and an end date. It is not an Action: it is never ticked off and never counts as progress.
_Avoid_: Course, lesson, lecture

**No-class Day**:
A date, or a range of dates such as a holiday week, when one Class or all Classes don't happen. Those Classes don't appear on the Timetable for those dates.
_Avoid_: Holiday, cancellation, break

**Class Schedule**:
All of the student's Classes for the semester.
_Avoid_: Course list, school timetable

**Progress Tracker**:
The record of Completions over time, shown separately for each Category.
_Avoid_: Stats, history, log

**Article**:
A piece of real Chinese writing the student pasted or photographed into the app: a 微信 post, a sign, a page of a textbook. It keeps its own text, a title taken from its first line, an optional **Source**, and the day it was imported. It is the unit that evidence is counted in: reading one Article can move a **Word** one step toward **Known**, and no further, however many times that word appears in it.
_Avoid_: Text, document, lesson, post

**Source**:
Optional free text saying where an Article came from, such as 微信公众号 or 茶馆菜单. It is the student's own writing and is never translated.
_Avoid_: URL, citation, origin

**Archived Article**:
An Article the student has put away. It leaves the reading list, its **Clean Sightings** still count, and it can be restored and reread. Articles are archived, never deleted, so the number of **Known** Words can never fall because of tidying up.
_Avoid_: Deleted article, hidden article, finished article

**Readability**:
What share of an **Article**'s measured **Words** the student already has **Known**, shown on the Article's row. It is information and never a gate: no Article is locked, hidden, reordered or marked too hard (ADR 0005).
_Avoid_: Difficulty, level, grade, score

**Banked Result**:
What one **Article** proved, kept from the moment 读完 first banked it: how many **Words** it made **Known**, how many it moved closer, and how many a **Lookup** sent back to zero. It is never recomputed, so a Word looked up next week doesn't rewrite what an Article proved in March, and an Article never finished has none rather than a row of zeros.
_Avoid_: Score, result, summary, report

**Reading Session**:
One sitting with one Article: the minutes it was on screen, and the **Lookups** made during it. It ends when the student presses 读完, which banks the Article's evidence and opens the Tick sheet with the minutes and the words met already filled in. The **Completion** it saves is an ordinary Completion in an ordinary Category, so reading counts toward a **Weekly Target** like anything else.
_Avoid_: Reading, study session, review session

**Word List**:
A fixed set of Chinese words at one HSK level, bundled with the app and never edited. The app carries HSK 4 (600 words) and HSK 5 (1,300 words) from the HSK 2.0 standard, each word with its pinyin and English. Words from HSK 1–3 are not carried: they are assumed known and are not measured.
_Avoid_: Dictionary, vocabulary, deck, syllabus

**Word**:
One entry in a **Word List**, together with what the student has done about it: its **Clean Sightings**, whether it is **Known**, and when. Chinese words outside HSK 4 and 5 are still split out of an Article and can still be looked up, but they carry no state and count toward nothing.
_Avoid_: Term, vocab item, character

**Lookup**:
The record that the student tapped a Word in an Article to see its pinyin and English. It is evidence of *not* knowing: a Lookup returns that Word's **Clean Sightings** to zero, and the Word must earn all of them again.
_Avoid_: Tap, hint, lookup failure

**Stubborn Word**:
A Word looked up in more than one Article and not yet **Known** — the app's own Lookups, read back rather than only spent. Two Lookups inside one Article count as one: it is the Articles that count, the same as a **Clean Sighting**, not the taps.
_Avoid_: Hard word, weak word, failed word, leech

**Word Note**:
The student's own free text on one Word: a memory trick, where they first met it, why it keeps slipping. It belongs to the Word, not to a day, so it is never a **Note** and never appears in the **Notes List** — that screen is about what happened on a day, this is about the Word itself.
_Avoid_: Note, mnemonic, hint, definition

**Clean Sighting**:
One Article the student read to the end without looking a Word up. A Word gains at most one Clean Sighting per Article, and only the first time that Article is finished: rereading proves nothing new. Each one remembers the Article it came from, so a Word can say where it was earned, and a **Lookup** takes them all away together.
_Avoid_: View, exposure, repetition, streak

**Known**:
A Word with three **Clean Sightings**: met in three different Articles, never looked up. The student can also mark a Word Known by hand, and can take it back, which returns it to zero. Known is the one number the year is measured by.
_Avoid_: Learned, mastered, acquired, retired

**Level**:
One **Word List** seen as progress: how many of its Words are **Known**, out of all of them. HSK 4 is out of 600, HSK 5 out of 1,300. The count is against the whole List, not the words that happened to appear in the student's Articles, so it only ever goes up.
_Avoid_: Stage, rank, tier, unlock

**Passed**:
A **Level** with four fifths of its Words **Known**. Passing HSK 4 is what makes HSK 5 the **Served Level**. Passing changes nothing about what the student is allowed to read: no Article is ever locked.
_Avoid_: Completed, unlocked, cleared, achieved

**Served Level**:
The **Level** the app draws **Daily New Words** from: HSK 4 until it is **Passed**, then HSK 5. Words of the level not yet served are still shown, still tappable and still counted when they turn up in an Article. Serving is about what the app offers, never about what the student may do.
_Avoid_: Current level, active level, unlocked level

**Daily New Words**:
Ten Words of the **Served Level** that the student has not met yet, offered once a day, each marked 认识 or 不认识. 认识 makes it **Known**; 不认识 sets the Word aside, and it may be offered again once thirty days have passed ([ADR 0006](docs/adr/0006-a-word-set-aside-comes-back.md)). There is no streak, no count of what is due, and no penalty for a day skipped: a day not opened leaves nothing behind.
_Avoid_: Review queue, flashcards, SRS, due words

**Set Aside**:
A **Word** that is not **Known** and has nothing happening to it: the student answered 不认识, looked it up, or read it without reaching three **Clean Sightings**. It leaves **Daily New Words** for thirty days from whichever of those happened last, then becomes offerable again, keeping any sightings it had. Nothing is owed in the meantime: a Set Aside Word is never due, never counted, and never shown as waiting.
_Avoid_: Due, scheduled, deferred, snoozed, leech
