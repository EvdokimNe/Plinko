--- What the player won: a weighted draw over baskets, and the score for it.
-- Knows nothing about rows, slots or pixels — a different board shape does not touch this file.
-- The points are earned the moment `draw` runs, before anything moves on screen.
local rng_source = require("features.board.logic.rng")

local M = {}

--- Prepares the draw. Weights are relative and normalised here, so {1,1} and {50,50} behave
--- identically and the caller never has to make them add up to anything.
---@param weights number[] relative chance per basket
---@param scores number[] points per basket
---@return table
function M.new(weights, scores)
	local cumulative = {}
	local total = 0
	for basket, weight in ipairs(weights) do
		total = total + weight
		cumulative[basket] = total
	end

	return {
		cumulative = cumulative,
		total = total,
		scores = scores,
		baskets = #weights,
	}
end

--- Draws a basket and the score that comes with it.
---@param state table
---@param rng table
---@return number basket
---@return number score
function M.draw(state, rng)
	local roll = rng_source.next(rng) * state.total

	for basket = 1, state.baskets do
		if roll < state.cumulative[basket] then
			return basket, state.scores[basket]
		end
	end

	-- Only reachable through floating point drift at the very top of the range.
	return state.baskets, state.scores[state.baskets]
end

--- The chance of each basket as a fraction of 1, for the debug readout.
---@param state table
---@return number[]
function M.chances(state)
	local chances = {}
	local previous = 0
	for basket = 1, state.baskets do
		chances[basket] = (state.cumulative[basket] - previous) / state.total
		previous = state.cumulative[basket]
	end
	return chances
end

return M
