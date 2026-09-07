# Pitfalls

Traps in Defold and in the libraries this project uses. Symptom first, then cause, then fix.
Read this before debugging anything that "should work". Add an entry whenever something costs
an hour.

## Engine

### A module's state is shared by everything that requires it
**Symptom:** two balls, two boards, or a reopened screen see each other's values.
**Cause:** `shared_state = 1` in `game.project` puts every script, gui script and module in one
Lua context, and `require` caches the module table in `package.loaded` for the whole process.
A module with internal state is a process-wide singleton.
**Fix:** stateless modules — `M.new(...)` returns a state table, every function takes it as the
first argument.

### A variable changes under you from unrelated code
**Symptom:** a value mutates with no local assignment in sight.
**Cause:** in Lua a bare assignment creates a *global*, and with `shared_state = 1` globals are
visible to every script and module in the game.
**Fix:** `local` on every declaration, without exception.

### Hot reloading a module changes nothing
**Symptom:** edit a module, reload, behaviour is identical.
**Cause:** re-evaluating the file creates a *new* table; existing `require` references still
point at the old one.
**Fix:** restart. Never ship the global-table workaround from the manual.

### Something depends on another object's `init()` and works only sometimes
**Symptom:** works in the editor, fails in a build, or the other way round.
**Cause:** Defold does not guarantee `init()` order between game objects.
**Fix:** wait for a message, never for luck.

### A closed screen still receives callbacks and writes into dead nodes
**Symptom:** a gui error about a deleted node, a moment after leaving the screen.
**Cause:** a service that outlives the screen still holds the callback the screen subscribed
with. A closure passed straight into `subscribe` cannot be named again, so it can never be
unsubscribed and the subscription survives the scene.
**Fix:** keep the callback on `self`, and unsubscribe exactly it in `final`.

### A physics body drifts away from its collision shape
**Symptom:** visuals and collisions disagree after moving an object.
**Cause:** `go.set_position` teleports a physics body outside the simulation.
**Fix:** forces and velocities only.

### A Lua module is "not found" at runtime although the file exists
**Symptom:** `module 'a.b.c' not found: no file 'a.b.c'`, but the file is right there.
**Cause:** bob resolves Lua dependencies by reading `require` **string literals** in the source.
`require(some_variable)` cannot be resolved, so the module is never packed into the build.
**Fix:** require with a literal string. Build lists of modules as lists of already-required
values, not lists of names.

### `--platform js-web` is rejected
**Symptom:** `SEVERE Platform js-web not supported`, exit code 1.
**Cause:** the asm.js target is gone. HTML5 is `wasm-web` (architectures `wasm-web` and
`wasm_pthread-web`).

## Druid

### The UI is silent — no clicks, no errors
**Cause:** `on_input` not forwarded to `self.druid:on_input(...)`, or the gui game object never
posted `acquire_input_focus`.

### Clicks fall through to the game behind the UI
**Cause:** the gui_script does not `return` the boolean that `druid:on_input` gives back.

### Nodes leak after a screen closes
**Cause:** `final` not forwarded to `self.druid:final()`.

### Build fails on a missing `event` module
**Cause:** Druid does not vendor `defold-event`; it is a separate pinned dependency.

### A global button style crashes on a button with no texture
**Symptom:** `Animation 'x' invalid for node 'y' (no animation set)` when clicking some button.
**Cause:** `druid.set_default_style` applies to **every** button in the game, including plain
coloured boxes with no atlas texture, and `gui.play_flipbook` on those is a runtime error.
**Fix:** check `gui.get_flipbook(node)` before swapping the sprite, so buttons that do not use
the shared art are left alone.

## Monarch

### The very first `monarch.show()` does nothing
**Cause:** screens register themselves in their screen script's `init()`, which has not run yet.
**Fix:** `msg.post("#", "show_first_screen")` in `init`, then call `monarch.show` from
`on_message`.

### A nested screen receives no input
**Cause:** nesting works only when the parent screen comes from a collection *factory*, not a
collection proxy.

### A reopened screen remembers the previous session
**Cause:** its Lua modules are still loaded and still hold state.
**Fix:** explicit reset on screen load.

## deftest

### A test passes alone and fails inside the suite
**Cause:** module-level state leaked from an earlier test.
**Fix:** stateless modules, or `deftest.util.unload`.

### A timing test flakes
**Cause:** real time instead of `deftest.mock.time`.
