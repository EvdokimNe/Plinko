# Board

The rules of the drop: which basket a ball wins, and how it gets there. Pure Lua, no Defold API.

## Two layers, deliberately apart

**Outcome** (`logic/outcome.lua`) decides the basket and the score from the configured weights.
It knows nothing about rows, slots or pixels.

**Route** (`logic/route.lua`) illustrates that decision: it picks a slot of the won basket and
the turn taken on each row. It decides nothing and cannot change where the ball lands.

They draw from **separate random streams**. Tuning how a fall looks can never move the odds, and
a change to `straightness` cannot make the distribution tests drift.

## Public API

```lua
board.new(board_config, width, height)          -- geometry and tables, built once
board.drop(state, outcome_rng, route_rng)       -- { basket, score, slot, positions }
board.pin_positions(state)                      -- { x, y, row, index }, for the view
board.slot_positions(state)                     -- { x, y, slot, basket }, for the view
board.ball_position(state, positions, row)      -- x, y after `row` rows; row 0 is the release
board.chances(state)                            -- configured chance per basket, fractions of 1
rng.new(seed) / rng.next(rng) / rng.below(rng, n)
```

`positions[row + 1]` is the number of right turns taken after `row` rows, so `positions[1]` is
always 0 and the last entry is always `slot - 1`.

## Decided, then paid

A drop has two moments and they are not the same thing.

**Decided** — `board.drop` fixes the basket, the score and the path. It must happen at the press,
or the configured probabilities could not hold. Nothing is displayed.

**Paid** — the ball reached its basket. `payout.release` hands the drop back, the balance moves,
`stats.record` counts it, the labels react.

Everything visible hangs off the second moment; the first only guarantees the second is not
random. While balls are in the air the balance reads "decided minus in flight" — that is correct,
not a bug: the points exist, they are held.

```lua
payout.new() / hold(state, drop) -> id / release(state, id) -> drop
payout.release_all(state) -> drops      -- leaving mid-fall pays everything at once
payout.pending(state)

stats.new(baskets) / record(state, basket, score) / reset(state)
stats.report(state, configured)   -- rows: basket, hits, share, configured, points
stats.totals(state)               -- drops, points
```

`stats` counts landings, never launches, and computes shares without formatting them —
rendering belongs to the debug layer.

## Presets

`config/board.lua` holds what every board shares — `view`, `fall`, `path`. `config/presets/*.lua`
override only shape and odds: `rows`, `basket_of_slot`, `weights`, `scores`. `config.get(id)`
merges them and caches per preset; `config.presets()` is the list the menu builds buttons from.

A basket may own several **adjacent** slots. `board.basket_cells(state)` merges contiguous runs
into one wide cell, so a wide basket draws as one cell with one label rather than four identical
ones. Slots of one basket that are not adjacent stay separate cells and the config reports it —
drawing one cell across a gap would misrepresent where balls land.

## Invariants

- The score is earned inside `drop`, before anything is animated. Closing the screen mid-fall
  loses the animation, never the win.
- A path always ends at the slot it was built for. Two counters enforce it: with `owed` right
  turns still needed and `remaining` rows left, going right has probability `owed / remaining`,
  which forces left when nothing is owed and right when every remaining row is owed.
- `straightness` (-1..1) only bends that probability by the drift from the straight line, and is
  clamped back inside the bounds. It changes the look, never the basket.
- A slot inside a basket is drawn in proportion to `C(rows, slot - 1)` — the number of distinct
  paths reaching it — so a wide basket behaves like a real board rather than a uniform pick.
- Pixel sizes come from the caller. The logic holds no hard-coded coordinates.
- The score is credited on release, never on decide. `payout.release_all` is what makes leaving
  the screen mid-fall lose the animation and keep the win.
- A held drop pays exactly once: releasing the same id twice returns nil the second time, so a
  double landing cannot double-credit.
- Closing the screen settles three things: falls in the air, entries still queued, and any
  remaining held payout. Queued balls were paid for, so they pay out even though they never flew.
- `release_all` returns drops in launch order, so a queued multi-drop settles predictably.
- Slots are 1-based (`1..rows + 1`) to match `basket_of_slot`; the number of right turns behind a
  slot is `slot - 1`.

## View

Pins, glows, baskets and balls are **cloned from hidden template nodes** in `game.gui`, never
laid out by hand: their positions come from the row count, so a hand-placed scene would freeze
`rows` and make the configurable board a lie.

```lua
board_view.build(state, view_config)   -- pins, glows, baskets, labels
ball_view.new(view_config)             -- pooled ball nodes
ball_view.take(state, x, y) / give(state, node) / give_all(state)
pool.new(create, size) / take / give / give_all / in_use / made
```

Every visual number lives in `config/board.lua` under `view`. Nothing about the look is written
into a script.

The scene uses two layers, `graphics` and `text`. Without them a hierarchy of mixed node types
breaks batching — pins, glows and ten basket labels would cost a draw call each instead of a
couple in total.

`max_nodes` in `game.gui` is raised to 1024: nine rows is about 100 nodes with glows, and
`rows = 15` would be 240 before the pool and the panel. Running out shows up as a failing
`clone_tree`, not as a warning.

## The fall

Position is a pure function of the path and a normalised time, so a fall owns no engine
animation and cancelling one is dropping it.

```lua
fall.new(geometry, positions, fall_config)   -- anchors and per-row timing
fall.position(state, t)                      -- x, y, row being crossed
fall.struck_pin(positions, row)              -- index into the flat pin list

falling.new(geometry, fall_config, handlers) -- handlers: on_land, on_strike
falling.launch(state, node, drop, payout_id)
falling.update(state, dt)
falling.cancel_all(state)                    -- returns the dropped balls
falling.count(state)
```

The last anchor is the basket, not the row above it, so a ball comes to rest inside the cell.
`row_pace` distributes the total time across rows: below 1 the ball accelerates, above 1 it
slows. The sideways arc and the hop both vanish at segment ends, so every row anchor is hit
exactly.

A ball entering row `r` from position `p` strikes pin `p + 1`, index `r(r-1)/2 + p + 1`. A test
checks the formula against the nearest pin by x, for every row and slot.

**Closing the screen cancels the falls and pays every held win.** The animation is disposable,
the win is not — two separate steps, `falling.cancel_all` and `payout.release_all`.

## The multi-drop queue

```lua
drop_queue.new(interval) / push(state, entries) / update(state, dt) -> entries
drop_queue.take_all(state) / count(state)
```

A press spends the balls, draws every outcome and holds every win **up front**; the queue only
spaces the launches out. Charging per launch would let the balance be spent elsewhere mid-queue,
leaving a press half done.

The first entry of an idle queue leaves immediately — waiting an interval before anything happens
reads as a dead button. A long frame releases several at once rather than losing them.

## Common pitfalls

- **A textbook LCG loses precision in Lua.** With multiplier `1103515245` the product exceeds
  2^53 and the double silently rounds, so the generator stops being uniform. `rng.lua` uses
  Park-Miller (`48271`, `2^31-1`), whose product stays inside the safe range.
- **`math.random` is not the same everywhere.** The engine runs LuaJIT on desktop and Lua 5.1 in
  the browser. Anything that must replay identically, or must not flake in a test, uses the
  seeded generator instead.
- **Sharing one random stream couples unrelated things.** Drawing the basket and the turns from
  the same generator makes a visual setting shift the outcomes for a given seed.
- **A pool that fails when empty breaks the debug grant.** Fifty balls at once must not crash the
  screen, so the pool creates another item instead of refusing.
- **Factorials overflow long before binomial coefficients do.** Path counts are built
  iteratively, `C(n, k+1) = C(n, k) * (n - k) / (k + 1)`.

## Known debt

- `DRIFT_RESPONSE` in `route.lua` is tuned by eye, not derived. It reads well at
  `straightness = ±1`, but if the parameter ever needs a documented unit, this is the constant to
  revisit.
- Nothing consumes `chances()` yet; it exists for the debug readout in task 009.
- Payout and stats state lives in the game screen, so counters reset on re-entry. If they should
  survive leaving the screen, the state moves next to the currency service — both modules are
  stateless, so it is a one-line move.
