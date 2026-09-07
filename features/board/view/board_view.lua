--- Draws the board: pins, their glows and the baskets.
-- Everything repeated is cloned from a hidden template node in the scene, because the positions
-- come from `board.pin_positions()` and change with the row count. Laying 45 pins out by hand
-- would freeze the row count into the scene and make a configurable board a lie.
local board = require("features.board.logic.board")

local M = {}

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
---@return table nodes { pins, glows, baskets, labels }
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
		gui.set_scale(glow, vmath.vector3(view_config.pin_scale * view_config.pin_glow_scale))
		glows[index] = glow

		local pin = clone_into(pin_template, pins_parent)
		gui.set_position(pin, vmath.vector3(position.x, position.y, 0))
		gui.set_scale(pin, vmath.vector3(view_config.pin_scale))
		pins[index] = pin
	end

	-- One node per drawn cell, not per slot: a basket spanning several slots is one wide cell.
	local baskets, labels = {}, {}
	local _, slot_y = board.slot_position_of(state, 1)

	for index, spec in ipairs(board.basket_cells(state)) do
		local cell, cloned = clone_into(basket_template, baskets_parent)
		gui.set_position(cell, vmath.vector3(spec.x, slot_y - view_config.basket_height / 2, 0))
		gui.set_size(cell, vmath.vector3(spec.width - 2, view_config.basket_height, 0))

		local label = cloned[gui.get_id(gui.get_node("basket_label"))]
		gui.set_text(label, tostring(spec.score))

		baskets[index] = cell
		labels[index] = label
	end

	return { pins = pins, glows = glows, baskets = baskets, labels = labels }
end

return M
