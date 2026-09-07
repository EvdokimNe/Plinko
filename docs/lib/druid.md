# Druid 1.3.0

> UI component framework for Defold. Logic layered over gui nodes you already placed.
> Insality, MIT. Requires `defold-event` (pinned tag 16). Full API in `plans/ref/lib/druid/`.

## Entry points
```lua
local druid = require("druid.druid")
self.druid = druid.new(self)          -- in gui_script init, `self` is the context
druid.set_default_style(style)        -- global, call once at boot
druid.set_text_function(fn)           -- localisation hook
druid.set_sound_function(fn)          -- sound hook for all components
```

## Instance lifecycle — all four are mandatory
```lua
function init(self)      self.druid = druid.new(self) end
function final(self)     self.druid:final() end
function update(self,dt) self.druid:update(dt) end
function on_input(self,action_id,action) return self.druid:on_input(action_id,action) end
function on_message(self,message_id,message,sender) self.druid:on_message(message_id,message,sender) end
```
`on_input` returns a boolean — return it, so a consumed click stops propagating.

## Components (`self.druid:new_*`)
Base: `new_button(node,[cb],[params],[anim_node])`, `new_text(node,[value],[no_adjust])`,
`new_grid(parent,item,[in_row])`, `new_scroll(view,content)`, `new_drag`, `new_hover`,
`new_blocker`, `new_back_handler`.
Extended: `new_progress(node,key,[init])`, `new_slider`, `new_input`, `new_timer`, `new_swipe`,
`new_hotkey`, `new_data_list(scroll,grid,create_fn)`, `new_layout`, `new_container`, `new_lang_text`.
Custom: `self.druid:new(component_class, ...)`, `self.druid:new_widget(widget,[template],[nodes],...)`.

## Widgets (the 1.x way to structure UI)
A widget is a class with its own `init`/`update`/`on_input`, created with `new_widget`. Prefer a
widget per screen area over a flat pile of components in one gui_script.

## Invariants
- Druid lives in `.gui_script`, never in `.script`.
- Callbacks receive `(self, ...)` where `self` is the context passed to `druid.new`.
- Component callbacks are `defold-event` objects: `button.on_click:subscribe(fn)` style where
  the component exposes events.

## Common pitfalls
- **UI does nothing, no error.** `on_input` not forwarded, or `acquire_input_focus` never posted
  for the gui game object.
- **Clicks pass through to the game below.** `on_input` result not returned from the gui_script.
- **Leak / stale nodes after a screen closes.** `final` not forwarded to `druid:final()`.
- **`event` module not found at build time.** `defold-event` dependency missing — Druid does not
  vendor it.
- **Style changes do not apply.** `set_default_style` called after instances were created.
