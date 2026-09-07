--- Ball views, taken from a pool.
-- The pool exists because a queued multi-drop puts several balls in the air at once and the
-- debug grant can push far more; creating and destroying nodes per drop would churn the scene
-- graph for nothing.
local pool = require("features.board.logic.pool")

local M = {}

--- Creates the pool of ball nodes.
---@param view_config table the `view` section of the board config
---@return table
function M.new(view_config)
	local template = gui.get_node("ball_template")
	local parent = gui.get_node("balls")
	local scale = vmath.vector3(view_config.ball_scale)

	return pool.new(function()
		local nodes = gui.clone_tree(template)
		local node = nodes[gui.get_id(template)]
		gui.set_parent(node, parent)
		gui.set_scale(node, scale)
		gui.set_enabled(node, false)
		return node
	end, view_config.ball_pool_size)
end

--- Takes a ball and shows it at a position.
---@param state table
---@param x number
---@param y number
---@return userdata node
function M.take(state, x, y)
	local node = pool.take(state)
	gui.set_position(node, vmath.vector3(x, y, 0))
	gui.set_enabled(node, true)
	return node
end

--- Hides a ball and returns it to the pool.
---@param state table
---@param node userdata
function M.give(state, node)
	gui.set_enabled(node, false)
	pool.give(state, node)
end

--- Hides and returns every ball currently out. Used when the screen closes mid-fall.
---@param state table
function M.give_all(state)
	for _, node in ipairs(pool.give_all(state)) do
		gui.set_enabled(node, false)
	end
end

return M
