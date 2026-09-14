# A Completion keeps its own copy of the Action's title and Category

Changing a Routine must not rewrite the past. Instead of storing a version history for each Action, every Completion saves a copy of the Action's title and Category at the moment it is ticked, and the Progress Tracker counts minutes by that saved Category. We chose this because it keeps progress correct while being simple enough for a first Swift app.

## Considered Options

- **Routine versions** (each change saved with a "from this date" label): every past day shows exactly what the Routine was, but it is much more complex to build and query.

## Consequences

- The title and Category look duplicated between Action and Completion. This is deliberate, not a bug to "clean up".
- A Missed day has no Completion, so it shows the Action's current title, not the title it had on that day.
