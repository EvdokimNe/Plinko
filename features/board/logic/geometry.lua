--- Where the pins, the falling ball and the slots are, in board-local coordinates with the
--- origin at the centre of the board and y growing upward.
-- The pyramid is derived from the board size, never hard-coded, so changing the row count or
-- the art size keeps everything aligned.
local M = {}

--- Builds the geometry.
-- `rows` rows of pins plus one level of slots share the height, so there are `rows + 1` levels.
-- Horizontally there are `rows + 1` slots; the step is sized so the outermost slot centres sit
-- half a step inside the board edge.
---@param rows number
---@param width number board width in pixels
---@param height number height available for pyramid and slots, in pixels
---@return table
function M.new(rows, width, height)
	local levels = rows + 1
	return {
		rows = rows,
		slots = rows + 1,
		step = width / levels,
		row_height = height / levels,
		top = height / 2,
	}
end

--- Centre of pin `index` (1..row) in `row` (1..rows).
---@return number x
---@return number y
function M.pin(geometry, row, index)
	local x = (index - (row + 1) / 2) * geometry.step
	local y = geometry.top - (row - 0.5) * geometry.row_height
	return x, y
end

--- Where a ball sits after passing `row` rows, having taken `rights` right turns.
-- `row` 0 is the release point above the first row.
---@return number x
---@return number y
function M.ball(geometry, row, rights)
	local x = (rights - row / 2) * geometry.step
	local y = geometry.top - row * geometry.row_height
	return x, y
end

--- Centre of slot `slot` (1..rows+1).
---@return number x
---@return number y
function M.slot(geometry, slot)
	local x = (slot - 1 - geometry.rows / 2) * geometry.step
	local y = geometry.top - (geometry.rows + 0.5) * geometry.row_height
	return x, y
end

--- How many pins the pyramid holds.
---@param rows number
---@return number
function M.pin_count(rows)
	return rows * (rows + 1) / 2
end

return M
