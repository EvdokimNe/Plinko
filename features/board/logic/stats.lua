--- What actually happened on this board: hits per basket, points, and how the real distribution
--- compares to the configured one.
-- Counts landings, never launches — a ball in flight has not happened yet.
-- Computes shares and never formats them; rendering belongs to the debug layer.
local M = {}

--- Empty counters for a board with `baskets` baskets.
---@param baskets number
---@return table
function M.new(baskets)
	local hits, points = {}, {}
	for basket = 1, baskets do
		hits[basket] = 0
		points[basket] = 0
	end
	return { baskets = baskets, hits = hits, points = points, drops = 0, total = 0 }
end

--- Records one landed ball.
---@param state table
---@param basket number
---@param score number
function M.record(state, basket, score)
	state.hits[basket] = state.hits[basket] + 1
	state.points[basket] = state.points[basket] + score
	state.drops = state.drops + 1
	state.total = state.total + score
end

--- Back to empty, keeping the basket count.
---@param state table
function M.reset(state)
	local fresh = M.new(state.baskets)
	state.hits = fresh.hits
	state.points = fresh.points
	state.drops = 0
	state.total = 0
end

--- One row per basket, for the debug readout.
-- `configured` comes from `board.chances()`; it is passed through untouched, so the reader can
-- compare what was asked for against what happened.
---@param state table
---@param configured number[] chance per basket, fractions of 1
---@return table[] rows { basket, hits, share, configured, points }
function M.report(state, configured)
	local rows = {}
	for basket = 1, state.baskets do
		rows[basket] = {
			basket = basket,
			hits = state.hits[basket],
			share = state.drops > 0 and state.hits[basket] / state.drops or 0,
			configured = configured[basket],
			points = state.points[basket],
		}
	end
	return rows
end

--- Totals across every basket.
---@param state table
---@return number drops
---@return number points
function M.totals(state)
	return state.drops, state.total
end

return M
