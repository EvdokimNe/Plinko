---@diagnostic disable: undefined-global
local route = require("features.board.logic.route")
local rng = require("features.board.logic.rng")

local function one_to_one(slots)
	local map = {}
	for slot = 1, slots do
		map[slot] = slot
	end
	return map
end

--- Average distance between the ball and the straight line to its slot. The measure
--- `straightness` is supposed to move.
local function average_drift(positions, slot, rows)
	local target = slot - 1
	local total = 0
	for row = 1, rows do
		local ideal = target * row / rows
		total = total + math.abs(positions[row + 1] - ideal)
	end
	return total / rows
end

return function()
	describe("Route", function()
		it("always ends in the slot it was built for", function()
			local rows = 9
			local state = route.new(rows, one_to_one(rows + 1))
			for slot = 1, rows + 1 do
				for seed = 1, 40 do
					local positions = route.build(state, slot, rng.new(seed), 0)
					assert(positions[#positions] == slot - 1,
						("slot %d seed %d ended at %d"):format(slot, seed, positions[#positions]))
				end
			end
		end)

		it("produces one position per row plus the release point", function()
			local rows = 9
			local state = route.new(rows, one_to_one(rows + 1))
			local positions = route.build(state, 5, rng.new(1), 0)
			assert(#positions == rows + 1)
			assert(positions[1] == 0)
		end)

		it("moves at most one step per row", function()
			local rows = 9
			local state = route.new(rows, one_to_one(rows + 1))
			for seed = 1, 30 do
				local positions = route.build(state, 6, rng.new(seed), 0)
				for row = 1, rows do
					local step = positions[row + 1] - positions[row]
					assert(step == 0 or step == 1, "illegal step " .. step)
				end
			end
		end)

		it("honours the slot at both extremes of straightness", function()
			local rows = 9
			local state = route.new(rows, one_to_one(rows + 1))
			for _, straightness in ipairs({ -1, 1 }) do
				for slot = 1, rows + 1 do
					local positions = route.build(state, slot, rng.new(slot * 13), straightness)
					assert(positions[#positions] == slot - 1)
				end
			end
		end)

		it("straightness pulls the ball towards the ideal line and away from it", function()
			local rows = 12
			local slot = 7
			local state = route.new(rows, one_to_one(rows + 1))

			local straight, loose = 0, 0
			local runs = 200
			for seed = 1, runs do
				straight = straight + average_drift(route.build(state, slot, rng.new(seed), 1), slot, rows)
				loose = loose + average_drift(route.build(state, slot, rng.new(seed), -1), slot, rows)
			end

			assert(straight / runs < loose / runs,
				("straight %.3f should drift less than loose %.3f"):format(straight / runs, loose / runs))
		end)

		it("picks slots of a wide basket in binomial proportion", function()
			-- 4 rows -> 5 slots, all owned by one basket. Paths per slot: 1,4,6,4,1 of 16.
			local state = route.new(4, { 1, 1, 1, 1, 1 })
			local source = rng.new(4242)

			local hits = { 0, 0, 0, 0, 0 }
			local draws = 16000
			for _ = 1, draws do
				local slot = route.pick_slot(state, 1, source)
				hits[slot] = hits[slot] + 1
			end

			local expected = { 1 / 16, 4 / 16, 6 / 16, 4 / 16, 1 / 16 }
			for slot = 1, 5 do
				local actual = hits[slot] / draws
				assert(math.abs(actual - expected[slot]) < 0.02,
					("slot %d expected %.3f got %.3f"):format(slot, expected[slot], actual))
			end
		end)

		it("handles a single row", function()
			local state = route.new(1, { 1, 2 })
			for slot = 1, 2 do
				local positions = route.build(state, slot, rng.new(slot), 0)
				assert(#positions == 2)
				assert(positions[2] == slot - 1)
			end
		end)

		it("only ever picks slots that belong to the basket asked for", function()
			-- 10 slots, 8 baskets: the outer baskets own two slots each.
			local map = { 1, 1, 2, 3, 4, 5, 6, 7, 8, 8 }
			local state = route.new(9, map)
			local source = rng.new(77)
			for _ = 1, 500 do
				for basket = 1, 8 do
					local slot = route.pick_slot(state, basket, source)
					assert(map[slot] == basket,
						("basket %d got slot %d which belongs to %d"):format(basket, slot, map[slot]))
				end
			end
		end)
	end)
end
