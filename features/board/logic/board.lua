--- The board feature's public API: build the tables once, then drop balls.
-- Two layers behind it, kept apart on purpose. `outcome` decides the basket and the score;
-- `route` only illustrates that decision. They draw from separate random streams, so tuning how
-- a ball looks on its way down can never move the odds.
local geometry = require("features.board.logic.geometry")
local outcome = require("features.board.logic.outcome")
local route = require("features.board.logic.route")

local M = {}

--- Builds the board.
-- Pixel sizes come from the caller, not from the config: the view knows how large the board art
-- actually is, and the logic should not carry hard-coded pixels.
---@param board_config table the `board` section of the config
---@param width number board width in pixels
---@param height number height available for pyramid and slots
---@return table
function M.new(board_config, width, height)
	return {
		config = board_config,
		geometry = geometry.new(board_config.rows, width, height),
		outcome = outcome.new(board_config.weights, board_config.scores),
		route = route.new(board_config.rows, board_config.basket_of_slot),
	}
end

--- Drops one ball. The score is earned here, before anything is animated.
---@param state table
---@param outcome_rng table decides the basket, nothing else touches it
---@param route_rng table decides the slot and the turns
---@return table drop { basket, score, slot, positions }
function M.drop(state, outcome_rng, route_rng)
	local basket, score = outcome.draw(state.outcome, outcome_rng)
	local slot = route.pick_slot(state.route, basket, route_rng)
	local positions = route.build(state.route, slot, route_rng, state.config.path.straightness)

	return {
		basket = basket,
		score = score,
		slot = slot,
		positions = positions,
	}
end

--- Pin centres, row by row, for the view to place its sprites.
---@param state table
---@return table[] list of { x, y, row, index }
function M.pin_positions(state)
	local positions = {}
	for row = 1, state.geometry.rows do
		for index = 1, row do
			local x, y = geometry.pin(state.geometry, row, index)
			positions[#positions + 1] = { x = x, y = y, row = row, index = index }
		end
	end
	return positions
end

--- Slot centres, left to right, each with the basket that owns it.
---@param state table
---@return table[] list of { x, y, slot, basket }
function M.slot_positions(state)
	local positions = {}
	for slot = 1, state.geometry.slots do
		local x, y = geometry.slot(state.geometry, slot)
		positions[slot] = {
			x = x,
			y = y,
			slot = slot,
			basket = state.config.basket_of_slot[slot],
		}
	end
	return positions
end

--- Where a ball is after `row` rows of the given path, in board-local pixels.
---@param state table
---@param positions number[] from a drop
---@param row number 0 = release point
---@return number x
---@return number y
function M.ball_position(state, positions, row)
	return geometry.ball(state.geometry, row, positions[row + 1])
end

--- Paths reaching each basket: the weights that reproduce the pyramid's own distribution.
-- A basket owning several slots gets the sum of their path counts.
---@param state table
---@return number[]
function M.natural_weights(state)
	local weights = {}
	for basket = 1, state.config.baskets do
		weights[basket] = 0
	end
	for slot, basket in ipairs(state.config.basket_of_slot) do
		weights[basket] = weights[basket] + state.route.counts[slot]
	end
	return weights
end

--- The configured chance of each basket, as fractions of 1. For the debug readout.
---@param state table
---@return number[]
function M.chances(state)
	return outcome.chances(state.outcome)
end

return M
