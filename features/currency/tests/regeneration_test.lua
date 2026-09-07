---@diagnostic disable: undefined-global
local regeneration = require("features.currency.logic.regeneration")

local function config()
	return {
		balls = { start = 10, regen = { amount = 1, seconds = 10, cap = 10 } },
		coins = { start = 0 },
	}
end

return function()
	describe("Regeneration", function()
		it("credits one unit per configured interval", function()
			local state = regeneration.new(config())
			assert(regeneration.update(state, 9.9, { balls = 5 }) == nil)

			local credits = regeneration.update(state, 0.2, { balls = 5 })
			assert(credits and credits.balls == 1)
		end)

		it("never touches a currency without a regen block", function()
			local state = regeneration.new(config())
			local credits = regeneration.update(state, 10000, { balls = 10, coins = 0 })
			assert(credits == nil)
			assert(state.rules.coins == nil)
		end)

		it("stays idle at the cap", function()
			local state = regeneration.new(config())
			for _ = 1, 100 do
				assert(regeneration.update(state, 1, { balls = 10 }) == nil)
			end
			assert(regeneration.time_to_next(state, "balls", 10) == nil)
		end)

		it("counts from the spend, not from a stale timer", function()
			local state = regeneration.new(config())
			-- Nine seconds accumulate while full: they must not carry over.
			regeneration.update(state, 9, { balls = 10 })
			assert(regeneration.update(state, 0.5, { balls = 9 }) == nil)
			assert(regeneration.time_to_next(state, "balls", 9) > 9)
		end)

		it("stays idle while a grant keeps the balance above the cap", function()
			local state = regeneration.new(config())
			for _ = 1, 50 do
				assert(regeneration.update(state, 1, { balls = 25 }) == nil)
			end
			-- Only once the balance falls back does the timer start, from zero.
			assert(regeneration.update(state, 9.9, { balls = 3 }) == nil)
			local credits = regeneration.update(state, 0.2, { balls = 3 })
			assert(credits and credits.balls == 1)
		end)

		it("credits several units for a long frame without passing the cap", function()
			local state = regeneration.new(config())
			local credits = regeneration.update(state, 100, { balls = 7 })
			assert(credits.balls == 3, "expected 3 got " .. tostring(credits.balls))
		end)

		it("reports the time to the next unit", function()
			local state = regeneration.new(config())
			assert(regeneration.time_to_next(state, "balls", 4) == 10)
			regeneration.update(state, 4, { balls = 4 })
			assert(math.abs(regeneration.time_to_next(state, "balls", 4) - 6) < 1e-9)
		end)

		it("reports nothing for a currency that never refills", function()
			local state = regeneration.new(config())
			assert(regeneration.time_to_next(state, "coins", 0) == nil)
		end)
	end)
end
