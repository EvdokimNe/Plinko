--- Balls currently in the air.
-- Each ball is a path, a time and a node. Advancing one is recomputing its position, so
-- cancelling is dropping it — nothing has to be unwound. See features/board/AGENTS.md.
local fall = require("features.board.logic.fall")

local M = {}

--- @param geom table board geometry
--- @param fall_config table the `fall` section of the board config
--- @param handlers table { on_land = fun(ball), on_strike = fun(pin_index) }
--- @return table
function M.new(geom, fall_config, handlers)
	return {
		geom = geom,
		config = fall_config,
		duration = fall_config.duration,
		handlers = handlers,
		balls = {},
	}
end

--- Starts a ball down its path.
---@param state table
---@param node userdata the pooled view
---@param drop table from `board.drop`
---@param payout_id number the held win this ball will release
function M.launch(state, node, drop, payout_id)
	state.balls[#state.balls + 1] = {
		node = node,
		drop = drop,
		payout_id = payout_id,
		motion = fall.new(state.geom, drop.positions, state.config),
		t = 0,
		row = 0,
	}
end

--- Advances every ball. Landed balls are reported through `on_land` and removed.
---@param state table
---@param dt number
function M.update(state, dt)
	local step = dt / state.duration

	for index = #state.balls, 1, -1 do
		local ball = state.balls[index]
		ball.t = ball.t + step

		local x, y, row = fall.position(ball.motion, ball.t)
		gui.set_position(ball.node, vmath.vector3(x, y, 0))

		if row > ball.row then
			ball.row = row
			state.handlers.on_strike(fall.struck_pin(ball.drop.positions, row))
		end

		if ball.t >= 1 then
			table.remove(state.balls, index)
			state.handlers.on_land(ball)
		end
	end
end

--- Drops every fall in flight and returns them. The wins they carry are settled by the caller
--- through the payout ledger, not here.
---@param state table
---@return table[] balls
function M.cancel_all(state)
	local cancelled = state.balls
	state.balls = {}
	return cancelled
end

--- How many balls are falling.
---@param state table
---@return number
function M.count(state)
	return #state.balls
end

return M
