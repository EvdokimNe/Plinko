--- The look of every button in the game.
-- Druid already animates the press, the hover and the click on a disabled button, so this does
-- not reimplement any of that: it extends the default style with the two things the default
-- cannot know — our pressed sprite, and how a disabled button should read.
-- Installed once from the composition root, so no screen repeats itself.
local default_style = require("druid.styles.default.style")

local NORMAL = "btn_green_normal"
local PRESSED = "btn_green_push"
local NORMAL_HASH = hash(NORMAL)

--- Dimming used for a button that cannot be pressed right now, e.g. the multi-drop below the
--- balls it costs.
local DISABLED_TINT = vmath.vector4(0.55, 0.55, 0.55, 1)
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

	local animate_click = button.on_click
	local animate_enabled = button.on_set_enabled

	--- Swaps to the pressed sprite, then lets Druid's own scale animation run.
	-- The style is global, so it also reaches buttons that are plain coloured boxes with no
	-- texture at all. Calling play_flipbook on those is a runtime error, so the swap only
	-- happens for nodes that actually show our button sprite.
	button.on_click = function(self, node)
		if gui.get_flipbook(node) == NORMAL_HASH then
			gui.play_flipbook(node, PRESSED)
			-- The sprite returns when the animation completes rather than on a timer, so a fast
			-- tap cannot leave the button stuck in its pressed frame.
			gui.animate(node, gui.PROP_SCALE, gui.get_scale(node), gui.EASING_LINEAR, 0.12, 0,
				function()
					gui.play_flipbook(node, NORMAL)
				end)
		end

		if animate_click then
			animate_click(self, node)
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
