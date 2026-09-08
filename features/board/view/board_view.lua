--- Draws the board: pins, their glows and the baskets.
-- Everything repeated is cloned from a hidden template node in the scene, because the positions
-- come from `board.pin_positions()` and change with the row count. Laying 45 pins out by hand
-- would freeze the row count into the scene and make a configurable board a lie.
local board = require("features.board.logic.board")

local M = {}

local ZERO_SCALE = vmath.vector3(0)
local WHITE = vmath.vector4(1)

local function clone_into(template, parent)
	local nodes = gui.clone_tree(template)
	local root = nodes[gui.get_id(template)]
	gui.set_parent(root, parent)
	gui.set_enabled(root, true)
	return root, nodes
end

--- Builds every pin, glow and basket for the given board state.
---@param state table from `board.new`
---@param view_config table the `view` section of the board config
---@return table nodes { pins, glows, baskets, labels } plus the glow's own tuning
function M.build(state, view_config)
	local pins_parent = gui.get_node("pins")
	local glows_parent = gui.get_node("glows")
	local baskets_parent = gui.get_node("baskets")

	local pin_template = gui.get_node("pin_template")
	local glow_template = gui.get_node("glow_template")
	local basket_template = gui.get_node("basket_template")

	local pins, glows = {}, {}
	for index, position in ipairs(board.pin_positions(state)) do
		local glow = clone_into(glow_template, glows_parent)
		gui.set_position(glow, vmath.vector3(position.x, position.y, 0))
		gui.set_scale(glow, ZERO_SCALE)
		gui.set_enabled(glow, false)
		glows[index] = glow

		local pin = clone_into(pin_template, pins_parent)
		gui.set_position(pin, vmath.vector3(position.x, position.y, 0))
		gui.set_scale(pin, vmath.vector3(view_config.pin_scale))
		pins[index] = pin
	end

	-- One node per drawn cell, not per slot: a basket spanning several slots is one wide cell.
	-- A basket whose slots are not adjacent draws as several cells, so the flash is addressed by
	-- basket and reaches every cell that basket owns.
	local label_template = gui.get_node("basket_label")
	local baskets, labels, cells_of_basket = {}, {}, {}
	local _, slot_y = board.slot_position_of(state, 1)

	for index, spec in ipairs(board.basket_cells(state)) do
		local cell, cloned = clone_into(basket_template, baskets_parent)
		gui.set_position(cell, vmath.vector3(spec.x, slot_y - view_config.basket_height / 2, 0))
		gui.set_size(cell, vmath.vector3(spec.width - 2, view_config.basket_height, 0))

		local label = cloned[gui.get_id(label_template)]
		gui.set_text(label, tostring(spec.score))

		baskets[index] = cell
		labels[index] = label
		cells_of_basket[spec.basket] = cells_of_basket[spec.basket] or {}
		table.insert(cells_of_basket[spec.basket], index)
	end

	return {
		pins = pins,
		glows = glows,
		baskets = baskets,
		labels = labels,
		cells_of_basket = cells_of_basket,
		glow_peak = vmath.vector3(view_config.pin_scale * view_config.pin_glow_scale),
		glow_grow = view_config.glow_grow,
		glow_fade = view_config.glow_fade,
		-- Read from the templates rather than restated here: the resting look belongs to the
		-- scene, and only the way back to it belongs to the code.
		basket_color = gui.get_color(basket_template),
		label_scale = gui.get_scale(label_template),
		basket_flash = view_config.basket_flash,
		label_bump = view_config.basket_label_bump,
	}
end

--- Flashes the glow under one pin: out of nothing, up to its peak, back to nothing.
-- A second strike on the same pin restarts the flash; the replaced animation drops its
-- callback, and the new one hides the node when it ends.
---@param nodes table from `M.build`
---@param index number pin index, as `on_strike` reports it
function M.pulse_glow(nodes, index)
	local glow = nodes.glows[index]
	if not glow then
		return
	end

	gui.set_scale(glow, ZERO_SCALE)
	gui.set_enabled(glow, true)
	gui.animate(glow, gui.PROP_SCALE, nodes.glow_peak, gui.EASING_OUTQUAD, nodes.glow_grow, 0,
		function()
			gui.animate(glow, gui.PROP_SCALE, ZERO_SCALE, gui.EASING_INQUAD, nodes.glow_fade, 0,
				function()
					gui.set_enabled(glow, false)
				end)
		end)
end

--- Marks the basket a ball just landed in: the cell flashes white and its number overshoots,
--- both easing back to what the scene says.
---@param nodes table from `M.build`
---@param basket number basket index, as `board.drop` reports it
function M.flash_basket(nodes, basket)
	for _, index in ipairs(nodes.cells_of_basket[basket] or {}) do
		local cell = nodes.baskets[index]
		gui.set_color(cell, WHITE)
		gui.animate(cell, gui.PROP_COLOR, nodes.basket_color, gui.EASING_OUTQUAD, nodes.basket_flash)

		local label = nodes.labels[index]
		gui.set_scale(label, nodes.label_scale * nodes.label_bump)
		gui.animate(label, gui.PROP_SCALE, nodes.label_scale, gui.EASING_OUTBACK, nodes.basket_flash)
	end
end

return M
