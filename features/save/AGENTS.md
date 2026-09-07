# Save

Persistence, behind one file.

## Public API

```lua
save.install()              -- loads the file, starts the library's autosave
save.bind(key, table)       -- -> the table to use; saved values are already in it
save.flush()                -- write now
save.wipe()                 -- delete the save
```

## Why a facade over one library call

[defold-saver](https://github.com/Insality/defold-saver) is good, but nothing else in the project
should know its name. Swapping it means editing this file, not hunting through features. The
currency service never requires it: the composition root hands it `save.bind` and `save.flush`
as plain callbacks.

## What is saved, and when

Currency balances, including `score`, under the key `currency`.

**Written after every balance change**, not on a timer and not on exit. A browser tab can close
without letting the game run its shutdown, so anything saved only at the end can be lost. A
balance change is also exactly the moment the player would hate to lose.

Refill timers are not saved: they are cheap to restart, and a stale countdown restored from disk
would be wrong anyway. Held payouts are not saved either — a ball in flight is not a promise, and
restoring animations across sessions is not worth it. What must survive is a win that was already
*shown*, and saving on change covers that.

## Invariants

- `save.bind` returns the table to keep using. The one passed in is populated with saved values,
  so the caller must not hold a reference from before the call.
- A first launch with no file leaves the config defaults in place.
- `install` runs before anything binds, and asserts otherwise.

## Known debt

- No versioning of the save format. If the currency list changes shape, an old file's values are
  copied in as they are. `saver` supports migrations; wire them if the shape ever changes.
- No corruption test: a broken file is the library's problem, and its behaviour there is
  untested by us.
