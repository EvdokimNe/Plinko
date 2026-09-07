--- How a win is shown: which slot of the drawn basket the ball enters, and how it turns on
--- every row to get there.
-- This layer decides nothing. The basket is already won when it runs; it can only produce a
-- path that ends exactly where the outcome said. Visual tuning lives here and cannot touch odds.
local rng_source = require("features.board.logic.rng")

local M = {}

--- How strongly `straightness` reacts to drift from the ideal line. Tuned by eye: at 1.0 the
--- ball is visibly purposeful without ever looking like it moves on rails.
local DRIFT_RESPONSE = 0.5

--- Number of distinct paths that reach each slot: slot `s` needs `s - 1` right turns out of
--- `rows`, so the count is the binomial coefficient. Built iteratively — the factorials
--- themselves overflow long before the coefficients do.
local function path_counts(rows)
	local counts = { 1 }
	for slot = 1, rows do
		counts[slot + 1] = counts[slot] * (rows - slot + 1) / slot
	end
	return counts
end

--- Prepares the route tables.
---@param rows number
---@param basket_of_slot number[] which basket sits under each slot, length rows + 1
---@return table
function M.new(rows, basket_of_slot)
	local counts = path_counts(rows)

	-- Slots grouped by basket, each with the running total of paths, so picking a slot inside a
	-- basket is one weighted draw rather than a search.
	local slots_of_basket = {}
	for slot, basket in ipairs(basket_of_slot) do
		local group = slots_of_basket[basket]
		if not group then
			group = { slots = {}, cumulative = {}, total = 0 }
			slots_of_basket[basket] = group
		end
		group.total = group.total + counts[slot]
		group.slots[#group.slots + 1] = slot
		group.cumulative[#group.cumulative + 1] = group.total
	end

	return {
		rows = rows,
		counts = counts,
		slots_of_basket = slots_of_basket,
	}
end

--- Picks which slot of `basket` the ball enters.
-- Not a uniform choice: a central slot is reachable by many more paths than an edge one, so a
-- basket spanning several slots catches balls the way a real board does.
---@param state table
---@param basket number
---@param rng table
---@return number slot
function M.pick_slot(state, basket, rng)
	local group = state.slots_of_basket[basket]
	local roll = rng_source.next(rng) * group.total

	for index = 1, #group.slots do
		if roll < group.cumulative[index] then
			return group.slots[index]
		end
	end

	return group.slots[#group.slots]
end

--- Builds the path into `slot`.
-- Two counters carry the guarantee: `remaining` rows left and `owed` right turns still needed.
-- Going right has probability `owed / remaining`, which keeps the walk inside the range of
-- reachable positions — when nothing is owed only left is possible, and when every remaining row
-- is owed only right. That is what makes the ball land exactly where it was sent.
-- `straightness` nudges that probability by how far the ball has drifted from the straight line
-- to its slot, and is clamped back inside the bounds, so it changes the look and never the end.
---@param state table
---@param slot number
---@param rng table
---@param straightness number -1..1
---@return number[] rights after each row, index 1 is the release point (always 0)
function M.build(state, slot, rng, straightness)
	local rows = state.rows
	local target = slot - 1

	local positions = { 0 }
	local rights = 0

	for row = 1, rows do
		local remaining = rows - row + 1
		local owed = target - rights

		local chance
		if owed <= 0 then
			chance = 0
		elseif owed >= remaining then
			chance = 1
		else
			chance = owed / remaining
			if straightness ~= 0 then
				local ideal = target * (row - 1) / rows
				local drift = rights - ideal
				chance = chance - straightness * drift * DRIFT_RESPONSE
				chance = math.max(0, math.min(1, chance))
			end
		end

		if rng_source.next(rng) < chance then
			rights = rights + 1
		end
		positions[row + 1] = rights
	end

	return positions
end

return M
