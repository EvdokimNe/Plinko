---@diagnostic disable: undefined-global
-- describe/it/before/after come from Telescope, injected by deftest at runtime.
local rng = require("features.board.logic.rng")

return function()
	describe("RNG", function()
		it("replays the same sequence for the same seed", function()
			local a, b = rng.new(12345), rng.new(12345)
			for _ = 1, 100 do
				assert(rng.next(a) == rng.next(b))
			end
		end)

		it("gives different sequences for different seeds", function()
			local a, b = rng.new(1), rng.new(2)
			local same = 0
			for _ = 1, 50 do
				if rng.next(a) == rng.next(b) then
					same = same + 1
				end
			end
			assert(same == 0)
		end)

		it("stays inside (0, 1)", function()
			local source = rng.new(7)
			for _ = 1, 5000 do
				local value = rng.next(source)
				assert(value > 0 and value < 1, "value out of range: " .. tostring(value))
			end
		end)

		it("survives a seed of zero", function()
			local source = rng.new(0)
			local value = rng.next(source)
			assert(value > 0 and value < 1)
		end)

		it("spreads values across the range", function()
			local source = rng.new(99)
			local buckets = { 0, 0, 0, 0 }
			for _ = 1, 4000 do
				local index = math.floor(rng.next(source) * 4) + 1
				buckets[index] = buckets[index] + 1
			end
			for index = 1, 4 do
				assert(buckets[index] > 800 and buckets[index] < 1200,
					"bucket " .. index .. " got " .. buckets[index])
			end
		end)

		it("returns integers in range from below()", function()
			local source = rng.new(3)
			for _ = 1, 500 do
				local value = rng.below(source, 6)
				assert(value >= 1 and value <= 6 and value == math.floor(value))
			end
		end)
	end)
end
