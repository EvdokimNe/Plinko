# Config

Every tunable number, by domain. `init.lua` merges the chosen preset over `board.lua`, clamps
what it can and repairs what it cannot, then hands back one table.

## Public API

```lua
config.get([preset_id])   -- the whole config for that board; defaults to "classic", cached
config.presets()          -- { id, label, board } per entry, the list the menu builds buttons from
config.reload()           -- drops the cache; tests call it, the game does not
```

## Adding a board

1. Write `config/presets/<id>.lua` returning `rows`, `basket_of_slot`, `weights`, `scores`.
2. Add one line to `config/presets.lua`: `{ id = "<id>", label = "<LABEL>", board = require("config.presets.<id>") }`.
3. Nothing else. The menu builds a button per entry.

The `require` must be a literal string — bob finds Lua dependencies by reading them, and a module
required through a variable never reaches the build.

## Invariants of a preset

- **`#basket_of_slot == rows + 1`.** N rows of pins produce N+1 slots. This is the count that
  gets it wrong; count the slots, not the rows.
- `basket_of_slot` maps slot to basket. Indices run `1..N` with no gaps — the basket count is
  the largest index, so a skipped number creates a basket that owns nothing.
- Slots of one basket must sit next to each other. A basket is drawn as a single cell, so
  `{ 1, 2, 2, 2, 2, 3 }` is a wide middle basket, and `{ 1, 2, 1 }` is a lie the view cannot tell.
- `#weights == #scores == basket count`, which is derived, never written down.
- `weights` are relative and normalised on use — `{ 5, 25, 70 }` and `{ 1, 5, 14 }` are the same
  odds. Negative is meaningless; all-zero would make every basket impossible.
- `scores` are whole points, per basket.
- A preset carries shape and odds only. Pin spacing, scales, fall tuning and path feel are shared
  by every board and live in `board.lua`.

## What init.lua does to a wrong table

It repairs rather than refuses, and says so on the console with a `CONFIG:` line. Read that line
instead of trusting the file:

- slot map of the wrong length → **thrown away** and rebuilt as one basket per slot
- `weights` or `scores` too short → padded (1 and 0); too long → extra entries dropped
- negative weight → 0; all weights zero → all set to 1
- a number outside its range in `RANGES` → clamped
- baskets whose slots are not adjacent → reported only, and they will draw as separate cells

Ranges live in one place, the `RANGES` table at the top of `init.lua`. A range whose field does
not exist is reported too — that means the config and the code have drifted apart.

## Pitfalls

- **A new board looks nothing like the preset.** The slot map was the wrong length and was
  silently rebuilt. Check the console for `CONFIG:`.
- **Changing `currency.start` does nothing.** A saved balance overrides it; `save.wipe()` clears
  the save.
- **Editing a preset at runtime leaks into the next `config.get`.** The merge copies tables, but
  the cache holds one table per preset id — call `config.reload()` between tests.
