# Plinko — project rules

Defold 1.13.1, target HTML5. UI: Druid. Screens: Monarch. Tests: deftest.
Everything written to disk is English. Conversation with the developer is Russian.

## Process
- Work starts with a plan in `plans/NNN-*.md`, then an **explicit start from the developer —
  every time**. A finished plan is not a start signal. `plans/` is gitignored and never ships.
- Commit only when the developer asks. No `Co-Authored-By` trailers.
- A document that was read is not retold back. Say only what is not in it: what collides with
  what exists, what is missing, what has to be decided.

## Layout
Features, not file types. Everything one feature needs sits in one folder.

```
main/                  bootstrap collection, entry script, Monarch screen registration
features/<name>/       one feature, self-contained
    logic/             pure Lua — no Defold API
    tests/             deftest suites for this feature's logic
    <name>.collection  scene, game objects, scripts, gui — the Defold side
    AGENTS.md          what it is, public API, invariants, pitfalls
shared/                pure Lua used by two or more features
assets/ui/shared/      art reused across screens (buttons)
assets/ui/game/        art of the play area (board, balls)
docs/                  DEPENDENCIES.md, and lib/*.md — notes on each library
test/                  deftest runner collection and the explicit suite list
```

Art lives in `assets/`, not inside a feature: one atlas serves the whole UI, so the sources it
packs belong together. Code and scenes stay in the feature.

- A feature is a folder, and its folder is its boundary. One feature never reaches into
  another's `logic/`; it goes through the other feature's public module or a message.
- **Rule of the second use:** write it inside the feature the first time, move it to `shared/`
  the second time. Do not generalise on the first occurrence.
- Defold resolves resources by absolute project path (`/features/board/board.collection`), so
  moving a folder means updating every path that points into it. Move deliberately.

## The rule everything else serves
Game logic lives in `features/<name>/logic/*.lua` and calls **no Defold API** — no `go.*`, no
`msg.*`, no `gui.*`, no `hash`, no `vmath` where a plain number works. A `.script` is a thin
shell: take input, call the logic, render the result. If logic cannot be tested without
starting the engine, it is in the wrong file.

## State
`shared_state = 1` is on: one Lua context for the whole game, and `require` caches a module in
`package.loaded` for the process lifetime. A module with internal state is therefore a
singleton shared by every component that requires it.
- Every variable is `local`. A global leaks across the entire game.
- Logic modules are stateless: `M.new(...)` returns a plain state table, and every function
  takes that state as its first argument. This is Defold's own recommended pattern, it makes
  two boards or two balls possible, and it is what makes the tests trivial.
- If a module must hold state anyway, it exposes an explicit `reset()` and the screen calls it
  on load. State that survives a collection reload is a bug, not a cache.

## Messages vs calls
- `msg.post` is a moment, and the way across a game-object or collection boundary.
- A direct module call is a question about a value. Never build a message bus where a function
  call does the job, and never reach into another game object's internals to avoid a message.
- Defold does not guarantee `init()` order between game objects. Anything that depends on
  another object being ready waits for a message, never for luck.

## Determinism
`dt` and the RNG are passed **into** the logic from outside. No `math.random`, no
`socket.gettime`, no `os.time` inside `logic/`. The seed is explicit and stored, so a ball drop
can be replayed and a test cannot flake.

## Physics
- Never move a physics body with `go.set_position`; use forces and velocities. Setting the
  position teleports the collision shape and desyncs it from the simulation.
- `hash()` results are constants — compute them once at file scope, never inside `update` or
  `on_input`.
- Tuning numbers (pin spacing, slot multipliers, restitution, gravity) live in one config
  module per feature. No magic numbers in scripts.

## Druid
- `druid.new(self)` in `init`, and forward **all** of `update`, `on_input`, `on_message`,
  `final`. A missing `on_input` is a silently dead UI; a missing `final` leaks.
- Druid components belong in `.gui_script`, not in `.script`.
- Druid requires `defold-event` — both are pinned in `game.project`, do not unpin them.

## Monarch
Screens are collection proxies driven by `monarch.show` / `monarch.back`. Never load or unload
a screen proxy by hand.

## Feature docs
Every feature folder carries an `AGENTS.md`, written in the condensed style of an `llms.txt`:
dense, no prose padding, and in this order.

1. **One line** — what the feature is.
2. **Public API** — one line per exported function: signature, what it returns, when to call it.
3. **Invariants** — what must stay true. State ownership, units, coordinate space, call order.
4. **Common pitfalls** — the mistakes that actually happened, symptom first, then the cause.
5. **Known debt** — recorded as fact, never hidden and never presented as an example to copy.

Read a feature's `AGENTS.md` before changing that feature. Write one when you create it.

## Files
Defold's `.collection`, `.go`, `.atlas`, `.input_binding` and `game.project` are plain text —
edit them directly, do not ask the developer to click in the editor. `.gui` is text too but
verbose and easy to corrupt: generate it carefully and say exactly what changed.

## Before writing a service, look for one
A service-shaped feature — currency, saving, logging, screen management, tweening — probably
already exists in the Defold ecosystem, written by someone who hit the edge cases first. Search
the [asset portal](https://defold.com/assets/) and
[awesome-defold](https://github.com/astrochili/awesome-defold) **before** writing it, not only
before adding a dependency, and say what was found and why it was or was not used.

Finding one does not mean taking it: a hundred lines of our own with tests can beat a dependency
whose model we would fight. But that has to be a decision, recorded in the feature's `AGENTS.md`,
rather than something nobody checked.

## Dependencies
`docs/DEPENDENCIES.md` owns the list: what each library is for, who wrote it, and the procedure
for adding another. Two rules that bite if forgotten — pin exact tags, never `master.zip`, and
respect the order: on a folder-name collision Defold silently keeps only the last entry.

## Documentation
Defold publishes an official LLM documentation set. Read the relevant page instead of guessing
an API or recalling it from memory:
- `https://defold.com/llms.txt` — entry point.
- `https://defold.com/llms/apis.md` — index of per-namespace API pages (`go`, `msg`, `physics`,
  `gui`, `render`, ...). Fetch the single namespace page you need.
- `https://defold.com/llms/manuals.md` — index of per-manual pages.

Never fetch `llms-full.txt` — it is 3.3 MB of combined text. Pages already pulled are cached in
`plans/ref/defold/`; check there first.

Druid, Monarch and deftest publish no such file. Their condensed notes live in `docs/lib/*.md`,
written from the library source under `.internal/lib/`, not from memory. Druid's own generated
API reference is cached in `plans/ref/lib/druid/` — read it there for exact signatures.

## Pitfalls
`PITFALLS.md` collects every Defold and library trap that cost time, symptom first. Read it
before debugging anything that "should work", and add to it every time something costs an hour.
Traps that belong to this workstation rather than to the project go in `plans/pitfalls-env.md`.

## Build and test
`docs/AUTOMATION.md` holds the commands and why each exists. The short version:

- **Bob** for anything reproducible — compile checks, the HTML5 bundle, CI. Needs Java 25 and
  **only runs from PowerShell**. HTML5 is `wasm-web`, not `js-web`.
- **The open editor's HTTP API** for everything interactive: `POST /command/build` to run the
  project, `GET /console` to read the output, `GET /preview/{path}` to see a scene as a PNG
  without opening it, `GET /ref` to search the engine API. Port and token are in
  `.internal/editor.port` and `.internal/editor.token`.
- **Tests** are a separate bundle: `test.settings` swaps the bootstrap collection for
  `/test/test.collection`, which requires every suite and runs deftest. A Windows bundle prints
  nothing to stdout, so the settings turn on `write_log_file` and the results are read from
  `log.txt` beside the executable.
- Suites are listed in `test/test.script` as **already-required values**, never as names:
  bob finds Lua dependencies by reading `require` string literals, and a module required through
  a variable never reaches the build.

There is no official Defold MCP server and none is needed — these are the supported interfaces.

## Approval
Ask before: committing or pushing, adding a dependency, changing `game.project` settings that
affect the build target, deleting anything the developer authored. Everything else inside the
project — writing code, scenes, atlases, docs — proceeds without asking.
