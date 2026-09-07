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

		it("offers every preset from the list", function()
			local presets = config.presets()
			assert(#presets >= 3)
			for _, preset in ipairs(presets) do
				assert(preset.id and preset.label and preset.board)
			end
		end)

		it("builds a different board per preset, keeping the shared visuals", function()
			local classic = config.get("classic")
			local wide = config.get("wide")

			assert(classic.board.rows == 9 and classic.board.baskets == 10)
			assert(wide.board.rows == 5 and wide.board.baskets == 3)
			assert(wide.board.fall.duration == classic.board.fall.duration,
				"fall tuning is shared, not duplicated per preset")
		end)

		it("keeps presets out of each other", function()
			local classic = config.get("classic")
			local left = config.get("left_heavy")
			assert(classic.board.weights[1] ~= left.board.weights[1])
			assert(config.get("classic").board.weights[1] == classic.board.weights[1])
		end)

		it("fails loudly on an unknown preset", function()
			assert(pcall(config.get, "no_such_board") == false)
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
			local board = require("config.presets.classic")
			board.basket_of_slot = { 1, 2, 3 }
			local c = config.get()
			assert(#c.board.basket_of_slot == c.board.rows + 1)
			assert(c.board.baskets == c.board.rows + 1)
		end)

		it("pads a short per-basket table", function()
			config.reload()
			local board = require("config.presets.classic")
			board.scores = { 10, 20 }
			local c = config.get()
			assert(#c.board.scores == c.board.baskets)
		end)

		it("replaces all-zero weights with equal weights", function()
			config.reload()
			local board = require("config.presets.classic")
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
