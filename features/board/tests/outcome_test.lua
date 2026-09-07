---@diagnostic disable: undefined-global
local outcome = require("features.board.logic.outcome")
local rng = require("features.board.logic.rng")

return function()
	describe("Outcome", function()
		it("returns the score configured for the basket it drew", function()
			local state = outcome.new({ 0, 1, 0 }, { 10, 20, 30 })
			local basket, score = outcome.draw(state, rng.new(5))
			assert(basket == 2)
			assert(score == 20)
		end)

		it("always draws the only basket with weight", function()
			local state = outcome.new({ 0, 0, 7, 0 }, { 1, 2, 3, 4 })
			local source = rng.new(11)
			for _ = 1, 500 do
				local basket = outcome.draw(state, source)
				assert(basket == 3)
			end
		end)

		it("follows the configured weights", function()
			local weights = { 10, 20, 70 }
			local state = outcome.new(weights, { 1, 1, 1 })
			local source = rng.new(2024)

			local hits = { 0, 0, 0 }
			local draws = 30000
			for _ = 1, draws do
				local basket = outcome.draw(state, source)
				hits[basket] = hits[basket] + 1
			end

			for basket = 1, 3 do
				local expected = weights[basket] / 100
				local actual = hits[basket] / draws
				assert(math.abs(actual - expected) < 0.02,
					("basket %d expected %.3f got %.3f"):format(basket, expected, actual))
			end
		end)

		it("treats weights as relative, not as percentages", function()
			local small = outcome.chances(outcome.new({ 1, 1 }, { 0, 0 }))
			local large = outcome.chances(outcome.new({ 50, 50 }, { 0, 0 }))
			assert(small[1] == large[1])
			assert(small[1] == 0.5)
		end)

		it("reports chances that add up to one", function()
			local chances = outcome.chances(outcome.new({ 3, 5, 12 }, { 0, 0, 0 }))
			local total = 0
			for _, chance in ipairs(chances) do
				total = total + chance
			end
			assert(math.abs(total - 1) < 1e-9)
		end)
	end)
end
