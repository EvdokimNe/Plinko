# Debug

A live readout of what the board is doing, on Tab.

## Public API

```lua
debug_overlay.new({ x, y })      -- top-left corner in screen pixels
debug_overlay.toggle(state)      -- -> visible
debug_overlay.is_visible(state)
debug_overlay.draw(state, stats_state, rows, status)

report.lines(stats_state, rows, status)   -- header, per-basket, total, status
report.weights_line(weights)              -- a config line ready to paste
```

`status` is `{ balls, in_flight, queued }`.

## Invariants

- `draw_debug_text` renders one frame and forgets, so `draw` is called every frame while
  visible and does nothing while hidden. The spec's `render:draw_text` is this message under its
  current name; the built-in render script handles it, no custom one is needed.
- `report` builds strings and nothing else, so the table is tested without a screen.
- Columns are padded to fixed widths — the debug font is monospaced, and a test checks that a
  four-digit count does not shift the header.
- Two percentage columns: what the config asked for, and what happened.

## Binomial weights

Opening the readout prints a `weights = { ... }` line matching the pyramid's own distribution:
each basket weighted by the number of paths reaching its slots. Paste it into `config/board.lua`
to make the configured odds equal the physical ones.

Printed rather than written to the file: a web build cannot write into the project, and editing
config behind the developer's back is worse than copying one line.

## Known debt

- The readout is drawn at a fixed screen position, not anchored, so it assumes the 720x1280
  reference resolution.
- No debug-only button panel: the grant button lives on the game screen itself, which the spec
  asks for anyway.
