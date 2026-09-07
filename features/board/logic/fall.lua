--- Where a ball is at a given moment of its fall.
-- Pure: position is a function of the path and a normalised time, with no engine-owned
-- animation, so a fall can be cancelled by dropping it. See features/board/AGENTS.md.
local geometry = require("features.board.logic.geometry")

local M = {}

--- Share of the total time each row takes. `row_pace` below 1 accelerates the fall, above 1
--- slows it down.
local function row_weights(rows, pace)
	local weights, total = {}, 0
	local weight = 1
	for row = 1, rows do
		weights[row] = weight
		total = total + weight
		weight = weight * pace
	end
	for row = 1, rows do
		weights[row] = weights[row] / total
	end
	return weights
end

--- Precomputes what does not change during a fall.
---@param geom table
---@param positions number[] right turns after each row, from `board.drop`
---@param fall_config table the `fall` section of the board config
---@return table
function M.new(geom, positions, fall_config)
	local rows = geom.rows
	local anchors = {}

	local x, y = geometry.ball(geom, 0, 0)
	anchors[0] = { x = x, y = y }

	for row = 1, rows - 1 do
		x, y = geometry.ball(geom, row, positions[row + 1])
		anchors[row] = { x = x, y = y }
	end

	-- The last anchor is the basket itself, not the row above it, so the ball comes to rest
	-- inside the cell.
	x, y = geometry.slot(geom, positions[rows + 1] + 1)
	anchors[rows] = { x = x, y = y }

	return {
		rows = rows,
		anchors = anchors,
		weights = row_weights(rows, fall_config.row_pace),
		bounce_x = fall_config.bounce_x,
		bounce_y = fall_config.bounce_y,
	}
end

--- Position at `t` in 0..1.
---@param state table from `M.new`
---@param t number
---@return number x
---@return number y
---@return number row the row being crossed, 1..rows
function M.position(state, t)
	t = math.max(0, math.min(1, t))

	local row = 1
	local elapsed = 0
	while row < state.rows and elapsed + state.weights[row] < t do
		elapsed = elapsed + state.weights[row]
		row = row + 1
	end

	local u = (t - elapsed) / state.weights[row]
	u = math.max(0, math.min(1, u))

	local from = state.anchors[row - 1]
	local to = state.anchors[row]

	-- Smoothstep: leaves a pin quickly, settles into the next one.
	local eased = u * u * (3 - 2 * u)
	local arc = math.sin(math.pi * u)
	local direction = to.x >= from.x and 1 or -1

	local x = from.x + (to.x - from.x) * eased + state.bounce_x * arc * direction
	local y = from.y + (to.y - from.y) * u + state.bounce_y * arc

	return x, y, row
end

--- Which pin the ball strikes entering `row`, as an index into the flat pin list.
-- A ball at position p above row r hits pin p + 1 of that row, because the pin centres are
-- offset by half a step from the ball lanes.
---@param positions number[]
---@param row number
---@return number index
function M.struck_pin(positions, row)
	return row * (row - 1) / 2 + positions[row] + 1
end

return M
