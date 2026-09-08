--- The look of every button in the game.
-- Druid already animates the press, the hover and the click on a disabled button, so this does
-- not reimplement any of that: it extends the default style with the two things the default
-- cannot know — our pressed sprite, and how a disabled button should read.
-- Installed once from the composition root, so no screen repeats itself.
local default_style = require("druid.styles.default.style")

local NORMAL = "btn_green_normal"
local PRESSED = "btn_green_push"
local NORMAL_HASH = hash(NORMAL)
local PRESSED_HASH = hash(PRESSED)

--- Dimming used for a button that cannot be pressed right now, e.g. the multi-drop below the
--- balls it costs.
local DISABLED_TINT = vmath.vector4(0.42, 0.42, 0.42, 1)
local ENABLED_TINT = vmath.vector4(1)

local M = {}

--- Builds the project style on top of Druid's default.
---@return table
function M.create()
	local style = {}
	for component, settings in pairs(default_style) do
		style[component] = settings
	end

	local button = {}
	for key, value in pairs(default_style.button or {}) do
		button[key] = value
	end

	local animate_hover = button.on_hover
	local animate_enabled = button.on_set_enabled

	--- Swaps the sprite for as long as the button is held. Druid reports hover for the touch
	--- that is down on the node, and always reports it false again — on release, on a drag off
	--- the node, and on an interrupted touch — so the pressed frame cannot get stuck.
	-- The style is global and also reaches buttons that are a bare text node or an untextured
	-- box, where the flipbook calls do not apply, hence both guards.
	button.on_hover = function(self, node, state)
		if gui.get_type(node) == gui.TYPE_BOX then
			local current = gui.get_flipbook(node)
			if state and current == NORMAL_HASH then
				gui.play_flipbook(node, PRESSED)
			elseif not state and current == PRESSED_HASH then
				gui.play_flipbook(node, NORMAL)
			end
		end

		if animate_hover then
			animate_hover(self, node, state)
		end
	end

	button.on_set_enabled = function(self, node, state)
		gui.set_color(node, state and ENABLED_TINT or DISABLED_TINT)
		if animate_enabled then
			animate_enabled(self, node, state)
		end
	end

	style.button = button
	return style
end

return M
