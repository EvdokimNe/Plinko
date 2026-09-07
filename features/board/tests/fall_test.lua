---@diagnostic disable: undefined-global
local fall = require("features.board.logic.fall")
local geometry = require("features.board.logic.geometry")
local rng = require("features.board.logic.rng")
local route = require("features.board.logic.route")

local ROWS = 9
local CONFIG = { duration = 1.2, row_pace = 0.9, escape = 2.2, hop = 12 }

local function geom()
	return geometry.new(ROWS, 560, 700)
end

local function path_to(slot, seed)
	local state = route.new(ROWS, (function()
		local map = {}
		for index = 1, ROWS + 1 do
			map[index] = index
		end
		return map
	end)())
	return route.build(state, slot, rng.new(seed or 1), 0)
end

return function()
	describe("Fall", function()
		it("starts at the release point", function()
			local g = geom()
			local state = fall.new(g, path_to(5), CONFIG)
			local x, y = fall.position(state, 0)
			local start_x, start_y = geometry.ball(g, 0, 0)
			assert(math.abs(x - start_x) < 1e-6)
			assert(math.abs(y - start_y) < 1e-6)
		end)

		it("ends in the centre of its basket, for every slot", function()
			local g = geom()
			for slot = 1, ROWS + 1 do
				local state = fall.new(g, path_to(slot, slot), CONFIG)
				local x, y = fall.position(state, 1)
				local slot_x, slot_y = geometry.slot(g, slot)
				assert(math.abs(x - slot_x) < 1e-6, ("slot %d ended at x=%s, want %s"):format(slot, x, slot_x))
				assert(math.abs(y - slot_y) < 1e-6)
			end
		end)

		it("never rises overall", function()
			local g = geom()
			local state = fall.new(g, path_to(4, 7), CONFIG)
			local previous = select(2, fall.position(state, 0))
			for step = 1, 200 do
				local _, y = fall.position(state, step / 200)
				-- The hop is inside a row, so compare across whole rows.
				if step % 20 == 0 then
					assert(y < previous, "ball rose between rows")
					previous = y
				end
			end
		end)

		it("passes exactly through every row anchor", function()
			local g = geom()
			local positions = path_to(6, 3)
			local state = fall.new(g, positions, CONFIG)

			local elapsed = 0
			for row = 1, ROWS - 1 do
				elapsed = elapsed + state.weights[row]
				local x, y = fall.position(state, elapsed)
				local anchor_x, anchor_y = geometry.ball(g, row, positions[row + 1])
				assert(math.abs(x - anchor_x) < 1e-6, ("row %d x off by %s"):format(row, x - anchor_x))
				assert(math.abs(y - anchor_y) < 1e-6)
			end
		end)

		it("stays on the board the whole way", function()
			local g = geom()
			local limit = 560 / 2 + 1
			for slot = 1, ROWS + 1 do
				local state = fall.new(g, path_to(slot, slot * 5), CONFIG)
				for step = 0, 100 do
					local x = fall.position(state, step / 100)
					assert(math.abs(x) <= limit, ("slot %d left the board at x=%s"):format(slot, x))
				end
			end
		end)

		it("clamps time outside 0..1", function()
			local g = geom()
			local state = fall.new(g, path_to(2), CONFIG)
			local before_x, before_y = fall.position(state, -5)
			local start_x, start_y = fall.position(state, 0)
			assert(before_x == start_x and before_y == start_y)

			local after_x = fall.position(state, 9)
			local end_x = fall.position(state, 1)
			assert(after_x == end_x)
		end)

		it("changes timing with row_pace but not the endpoint", function()
			local g = geom()
			local positions = path_to(8, 11)
			local fast = fall.new(g, positions, { duration = 1, row_pace = 0.6, escape = 1, hop = 0 })
			local slow = fall.new(g, positions, { duration = 1, row_pace = 1.5, escape = 1, hop = 0 })

			assert(fast.weights[1] > fast.weights[ROWS], "row_pace below 1 should speed up")
			assert(slow.weights[1] < slow.weights[ROWS], "row_pace above 1 should slow down")

			local fast_x, fast_y = fall.position(fast, 1)
			local slow_x, slow_y = fall.position(slow, 1)
			assert(math.abs(fast_x - slow_x) < 1e-6)
			assert(math.abs(fast_y - slow_y) < 1e-6)
		end)

		it("names the pin nearest the ball for every row and position", function()
			local g = geom()
			for slot = 1, ROWS + 1 do
				local positions = path_to(slot, slot * 3)
				for row = 1, ROWS do
					local index = fall.struck_pin(positions, row)

					local ball_x = geometry.ball(g, row - 1, positions[row])
					local nearest, nearest_distance
					local flat = 0
					for candidate_row = 1, ROWS do
						for candidate = 1, candidate_row do
							flat = flat + 1
							if candidate_row == row then
								local pin_x = geometry.pin(g, candidate_row, candidate)
								local distance = math.abs(pin_x - ball_x)
								if not nearest_distance or distance < nearest_distance then
									nearest_distance = distance
									nearest = flat
								end
							end
						end
					end

					assert(index == nearest,
						("row %d slot %d: formula says %d, nearest is %d"):format(row, slot, index, nearest))
				end
			end
		end)
	end)
end
