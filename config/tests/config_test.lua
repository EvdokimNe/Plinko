---@diagnostic disable: undefined-global
-- describe/it/before/after come from Telescope, injected by deftest at runtime.
local config = require("config.init")

return function()
	describe("Config", function()
		before(function()
			config.reload()
		end)

		after(function()
			config.reload()
		end)

		it("loads every domain", function()
			local c = config.get()
			assert(c.board)
			assert(c.currency)
			assert(c.drop)
		end)

		it("derives the basket count from the slot map instead of storing it", function()
			local c = config.get()
			assert(c.board.baskets == 10)
			assert(#c.board.basket_of_slot == c.board.rows + 1)
		end)

		it("clamps a number above its range", function()
			config.reload()
			local board = require("config.board")
			board.path.straightness = 5
			local c = config.get()
			assert(c.board.path.straightness == 1)
		end)

		it("clamps a number below its range", function()
			config.reload()
			local board = require("config.board")
			board.fall.duration = 0.001
			local c = config.get()
			assert(c.board.fall.duration == 0.2)
		end)

		it("rebuilds a slot map of the wrong length as one basket per slot", function()
			config.reload()
			local board = require("config.board")
			board.basket_of_slot = { 1, 2, 3 }
			local c = config.get()
			assert(#c.board.basket_of_slot == c.board.rows + 1)
			assert(c.board.baskets == c.board.rows + 1)
		end)

		it("pads a short per-basket table", function()
			config.reload()
			local board = require("config.board")
			board.scores = { 10, 20 }
			local c = config.get()
			assert(#c.board.scores == c.board.baskets)
		end)

		it("replaces all-zero weights with equal weights", function()
			config.reload()
			local board = require("config.board")
			for basket = 1, #board.weights do
				board.weights[basket] = 0
			end
			local c = config.get()
			local total = 0
			for _, weight in ipairs(c.board.weights) do
				total = total + weight
			end
			assert(total > 0)
		end)

		it("keeps a currency without regen from ever regenerating", function()
			config.reload()
			local currency = require("config.currency")
			currency.coins = { start = 0 }
			local c = config.get()
			assert(c.currency.coins.regen == nil)
		end)
	end)
end
