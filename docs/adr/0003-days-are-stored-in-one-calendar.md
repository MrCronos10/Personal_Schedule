# Days are stored in one calendar, not the phone's

A **Day** is stored as the number yyyymmdd, and that number is always read and written in the Gregorian calendar, whatever calendar the phone is set to. The student's phone is set to Thailand, where iOS uses the Thai Buddhist calendar and the year runs 543 ahead, so `Calendar.current` numbered today as 25690918 instead of 20260918. Every day, Completion, Routine start day and Pause was being stored with that year. The app was consistent with itself, so nothing looked wrong, but the number no longer meant a fixed day: after a change of region the same stored number would be read as a day 543 years away. A Routine's start day would then sort after today and the Routine would quietly stop appearing, and history would look empty.

Screens are unaffected: they format a real moment, so a date still appears in the student's own calendar, and 9月18日 is still 9月18日 in Thailand. Only the stored number is pinned.

The time zone stays the phone's, because which day a moment falls on genuinely is local. It is read once when the app first needs a Day, so crossing time zones settles on the next start.

## Considered Options

- **Store a `Date` instead of a number**: no era problem, but every "is this the same day" comparison then needs a calendar anyway, and days stop sorting and comparing as plain numbers, which is what makes the day rule simple to read and test.
- **Keep the phone's calendar and record which one was used**: keeps what was already stored, but every read has to convert, and two phones in different regions would hold numbers that can't be compared.
- **Leave it**: it only breaks if the region changes. Rejected because it breaks silently, in a way that looks like lost data, and gets more expensive to fix with every day of history.

## Consequences

- Days already stored with the Buddhist year have to be converted once. The migration moves only years between 2500 and 2700, which is where a Buddhist reading of a day this app could have written lands, and leaves every other number alone. That covers the student's own phone and can run safely more than once. It is deliberately not a general "any other calendar" conversion: a day written under a calendar we haven't planned for is left as it is rather than guessed at, because guessing wrong rewrites history instead of preserving it. See `DayMigration`.
- Nothing in the app passes a calendar to the day rule any more. The rule reads the weekday from the Day itself, so a caller can't reintroduce this by passing the wrong one — which is how it arrived, in a weekday test that had to name a calendar to pass.
- A `Day` is only meaningful with its calendar, so a stored number must never be built or read with `Calendar.current`. Use `Day`'s own initialisers.
