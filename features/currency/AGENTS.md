# Currency

Balances and their refilling, for the whole session rather than for one screen.

## Shape

**`logic/wallet.lua`** — balances by id, `get` / `add` / `spend` / `snapshot`. No time, no events.
**`logic/regeneration.lua`** — refill rules by id. Given `dt` and the current balances it
*reports* what should be credited; it writes nothing itself.
**`currency.lua`** — the service. Holds the state, applies the credits, notifies subscribers.

## Public API

```lua
currency.install(currency_config)   -- once, from main/services/currency.script
currency.uninstall()
currency.update(dt)                 -- driven by the service script

currency.balance(id)                -- number
currency.add(id, amount)            -- may exceed the refill cap
currency.spend(id, amount)          -- boolean, all or nothing
currency.time_to_next(id)           -- seconds, or nil when full or non-refilling
currency.on_change(id, callback)    -- callback(balance)
currency.off_change(id, callback)
```

## Why the state lives in a module

Defold has no dependency injection, and this service genuinely outlives every screen: the menu
displays the count, the game screen spends, and refilling continues while neither is open.
Routing every read through messages would make each one an async round trip for nothing.

This is also the engine's own pattern — Monarch keeps its screen stack in module state, Druid its
widget registry — and the state here is created at one known point through `install`, which
asserts if called twice. That is the difference the project rules care about: a singleton built
deliberately by the composition root, not a global that appeared by accident.

The logic behind it stays stateless: `wallet` and `regeneration` are `new(config) -> state`
modules, and every test drives them directly without touching the service.

## Invariants

- The cap belongs to the **refill rule**, not to the currency. A grant may push the balance above
  it; refilling then idles until the balance falls back.
- The refill timer only runs below the cap, and is held at zero at or above it. Time spent full
  never accumulates into a burst of instant refills after one spend.
- Reaching the cap resets the timer, so the next spend starts a whole interval rather than
  crediting immediately.
- A currency configured without a `regen` block never appears in the timers and never refills.
- One `update` may credit several units if `dt` was large, but never past the cap.
- `spend` is all or nothing: an insufficient balance is refused whole, never partially.
- An unknown currency id fails loudly. A missing balance is a wiring bug, not a zero.
- Refilling advances on `dt`, not on wall clock, so it is deterministic and testable.

## Common pitfalls

- **A subscription outlives the screen that made it.** The service is permanent; a callback left
  behind writes into destroyed gui nodes. Screens keep the closure on `self` and unsubscribe in
  `final`.
- **A part-filled timer at the cap is a free ball.** Without holding the timer at zero while
  full, a player who spends one unit after idling gets an instant refill.

## Alternatives considered

[Insality/defold-token](https://github.com/Insality/defold-token) (MIT) does this job as a
library: countable values with configurable restoration, `set_restore_config`,
`get_time_to_restore`, `reset_restore_timer`, plus save/load of its own state. It was found
after this feature was written — the project rules now require looking first.

Kept ours because it is about a hundred lines of logic with no dependency, shaped exactly to the
spec, and covered by tests that double as documentation of the refill rules. Token is the better
choice the moment a second currency needs shops, offers or bundles: it already models what we
would otherwise grow here by hand.

[indiesoftby/defold-page-visibility](https://github.com/indiesoftby/defold-page-visibility)
reports when a browser tab is hidden. Not needed yet: the refill timer is driven by `dt` and
capped, so a tab that returns after a minute credits at most up to the cap and never bursts.
It becomes relevant if refilling should keep honest time while the tab is in the background.

## Known debt

- No persistence. Balances reset on restart until the save service exists (task 010).
- `time_to_next` is polled by whoever draws the countdown, since a per-second event would be
  noise. If a second consumer appears, reconsider.
