# A Word set aside comes back after thirty days

Any **Word** that is not **Known** and has nothing happening to it is **Set Aside**: it leaves **Daily New Words** for thirty days and is then offerable again. Until now such a Word left for good, which quietly made the **Level** unfinishable.

The hole was real and invisible. `markNotKnownToday` writes a `WordProgress` row, and **Daily New Words** offers only Words with no row at all, so every Word the student ever admitted to not knowing — and every Word they tapped in an **Article** — was gone from the daily ten permanently. Its only remaining path to **Known** was three **Clean Sightings** in three different Articles with no **Lookup** in between. ADR 0005 already states that reading alone will never finish a Level, which is the whole reason **Daily New Words** exists; so the Words most in need of it were the exact Words it had stopped serving. **Passed** needs 480 of HSK 4's 600, and a few hundred Set Aside Words is an ordinary year — the meter could stall for good with nothing on screen to say why. `CONTEXT.md` had said all along that 不认识 "returns it to the pool for another day"; the code and its pinned test said otherwise, and the glossary was the one describing the app the student wanted.

## Considered Options

- **Change the glossary instead, and accept parked Words.** Honest, one line of work, and it makes the headline number a measure of the easy words only. Rejected: it quietly redefines the year's one number as "what reading happened to cover", which is the thing ADR 0005 refused.
- **Spaced repetition over Set Aside Words**, with intervals that widen on success. More accurate, and precisely the abandoned deck ADR 0004 exists to prevent. Rejected on the same grounds it was rejected the first time.
- **A fixed thirty days, no widening, no state beyond the day it was set aside.** Chosen. It is eligibility, not obligation: the Word simply becomes offerable again, and if the student never opens the tab, nothing accrues.

## Consequences

- ADR 0004 stands in full. There is still no queue, no due date, no debt and no streak: a Set Aside Word that comes back is offered like any other unmet Word, and a day not opened still leaves nothing behind.
- The thirty days is blunt on purpose. It is not tuned, not per-Word and not earned; a Word answered 不认识 four times running comes back on the same schedule as one answered once. Anything cleverer is an interval schedule wearing a different hat.
- A Word can now be offered, set aside, and offered again without ever being read, so `WordProgress` has to remember *when* it was set aside, not merely that it was.
- **The wait covers Words part-way to Known, not only Words at zero.** A Word read cleanly in one **Article** and never met again would otherwise sit at one or two **Clean Sightings** for good: the same stall, reached through reading instead of 不认识. So finishing an Article starts the clock on every Word it touched, and the rule is simply "not Known, and nothing for thirty days". A Word offered again keeps the sightings it had — being offered is another chance, never a reason to lose earned evidence. The cost is that 认识 on a two-sighting Word skips its third Article, which is the manual override ADR 0004 already allows everywhere.
- **Daily New Words** now has two empty days, and has to tell them apart. Nothing offerable today because everything left is inside its wait is not the same as nothing left to learn, and the screen may not say 这一级的词都见过了 for the first. It says so without a count of what is waiting or a date it returns: a Set Aside Word is never due, and a number there would be the queue ADR 0004 turned down.
