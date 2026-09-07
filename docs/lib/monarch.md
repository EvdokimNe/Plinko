# Monarch 6.0.2

> Screen manager for Defold: a stack of screens, each its own collection, shown through a
> collection proxy or collection factory. Björn Ritzl, MIT.

## Screen setup
One game object per screen, carrying either
- a `collectionproxy` + Monarch's `screen_proxy.script`, or
- a `collectionfactory` + Monarch's `screen_factory.script`.

Script properties: `screen_id` (hash, unique), `screen_proxy`/`screen_factory` url, `popup`,
`popup_on_popup`, `timestep_below_popup`, `preload`, and the input-focus flags.
Monarch's editor script can generate `.collection` + `.gui` + `.gui_script` for a screen.

## Navigation
```lua
monarch.show(id, [options], [data], [cb])   -- push; options: clear, reload, no_stack, sequential
monarch.replace(id, [options], [data], [cb])
monarch.back([options], [data], [cb])       -- pop
monarch.hide(id, [cb])                      -- for no_stack / popup screens
monarch.clear([cb])
monarch.preload(id, [options], [cb])        -- load without showing
monarch.unload(id, [cb])
```
Queries: `in_stack`, `is_top`, `is_visible`, `is_loaded`, `is_popup`, `is_busy`, `screen_exists`,
`get_stack`, `top([offset])`, `bottom([offset])`, `data(id)`.
Hooks: `on_transition(id, fn)`, `on_focus_changed(id, fn)`, `on_post(id, fn_or_url)`,
`add_listener(url)`. Messaging: `monarch.post(id, message_id, message)`.

## Invariants
- Navigation is a stack: `show` pushes, `back` pops. A popup shows on top without hiding the
  screen below.
- `show` is asynchronous — the collection loads over several frames. Calls made while
  `monarch.is_busy()` are queued.
- `data` passed to `show` is retrievable inside the screen via `monarch.data(id)`.

## Common pitfalls
- **First `monarch.show()` silently does nothing.** The screen scripts' `init()` registers the
  screens, and it has not run yet. Delay the first call: `msg.post("#", "show_first_screen")`
  in `init`, call `monarch.show` from `on_message`.
- **Nested screens get no input.** Sub-screens work only when the parent is a collection
  *factory*, not a proxy.
- **Screen state survives a reopen.** A proxy screen keeps its Lua module state — the module is
  cached process-wide. Reset explicitly on load.
- **Two shows race.** Fire-and-forget `show` calls interleave; use the callback or `sequential`.
