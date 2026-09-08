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

### A hand-written GUI template instance lands in the corner at default size
**Symptom:** a `type: TYPE_TEMPLATE` node written into a `.gui` by hand renders its children at
the origin with the template's own sizes, ignoring what the instance says.
**Cause:** the instance is flattened at build time — the engine only ever sees the children, each
named `instance_id/child_id`. Every child of the template scene must be listed in the consuming
file as its own `nodes` entry with that prefixed id, `template_node_child: true` and a `parent`
chain rooted at the instance id. A missing or misparented child inherits nothing, and the
instance has no runtime node of its own to fall back on.
**Fix:** mirror the editor's own output. Only overridden properties are written on a child, with
their protobuf field numbers in `overridden_fields` (position 1, scale 3, size 4, color 5,
text 8, pivot 14); everything else is left out and comes from the template scene. Give the
template a single root node so a script can move the whole instance.
**Also:** a scene node cannot be authored inside an instance — the editor only overrides what the
template already has. A screen that wants its content inside a window keeps that content as its
own node and parents it in at runtime.

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

### A nine-sliced button looks squashed at a small size
**Symptom:** the corners of the sprite bleed into each other and the middle disappears once the
node is made smaller.
**Cause:** the slice9 borders are drawn at their own pixel size and never shrink. A node shorter
than `top + bottom`, or narrower than `left + right`, has no middle left to stretch and the
corners start overlapping. Our button carries a border of 40 on every side, so it cannot go under
80 pixels either way — at its 200x88 that leaves eight pixels of stretchable middle in height.
**Fix:** give a small control a different shape rather than a smaller instance of a big one. The
debug control is a plain text node, like BACK.

### A button keeps its pressed sprite after one click
**Symptom:** the button changes colour on the first press and never changes back.
**Cause:** the sprite was restored in the completion callback of a `gui.animate` on
`PROP_SCALE`, and Druid's own `on_click` animates that same property immediately afterwards. The
second animation replaces the first, and a replaced `gui.animate` never calls its callback.
**Fix:** a pressed sprite belongs on `on_hover`, which Druid raises for the touch that is down on
the node and always lowers again — on release, on a drag off the node, and on an interrupted
touch. Never time a state change with an animation on a property something else also drives.

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

### The screen goes black for a moment between two screens
**Symptom:** a flash of the window's clear colour while navigating.
**Cause:** `show()` starts `show_in` for the new screen and `show_out` for the old one as two
coroutines. `show_in` yields waiting for `async_load`, so `show_out` runs first and unloads the
outgoing screen while the incoming collection is still loading. Nothing is drawn in between.
**Fix:** set the clear colour in `game.project` to whatever the screens sit on, so those frames
are indistinguishable — ours is the same blue as the `background` node in both scenes, and the
two have to be changed together. Cover the gap with motion instead by registering a
`TRANSITION_SHOW_OUT` on the outgoing screen: Monarch waits for it, so the old screen stays up
while the new one loads.

### `preload` on a screen proxy is not a cache — the screen stops resetting
**Symptom:** a screen keeps the previous visit's board, score or subscriptions; a preset chosen
in a menu is ignored on the second entry.
**Cause:** with the proxy's `preload` property set, Monarch's `unload` posts `disable` instead of
`unload`. The collection stays alive, so `final()` never runs and `init()` never runs again — the
screen is only hidden and shown.
**Fix:** leave `preload` off for any screen that builds itself from data in `init()`. It suits a
screen that is genuinely static.

## deftest

### A test passes alone and fails inside the suite
**Cause:** module-level state leaked from an earlier test.
**Fix:** stateless modules, or `deftest.util.unload`.

### A timing test flakes
**Cause:** real time instead of `deftest.mock.time`.
