---@diagnostic disable: undefined-global
local board = require("features.board.logic.board")

local BASE = {
	view = { width = 560, height = 700 },
	path = { straightness = 0 },
	fall = { duration = 1, row_pace = 1, escape = 1, hop = 0 },
}

local function make(rows, basket_of_slot, scores)
	local settings = {
		rows = rows,
		basket_of_slot = basket_of_slot,
		weights = {},
		scores = scores,
		baskets = 0,
		path = BASE.path,
		fall = BASE.fall,
	}
	for _, basket in ipairs(basket_of_slot) do
		settings.baskets = math.max(settings.baskets, basket)
	end
	for basket = 1, settings.baskets do
		settings.weights[basket] = 1
	end
	return board.new(settings, BASE.view.width, BASE.view.height)
end

return function()
	describe("Basket cells", function()
		it("gives one cell per slot when baskets do not span", function()
			local state = make(5, { 1, 2, 3, 4, 5, 6 }, { 1, 2, 3, 4, 5, 6 })
			local cells = board.basket_cells(state)

			assert(#cells == 6)
			for _, cell in ipairs(cells) do
				assert(math.abs(cell.width - state.geometry.step) < 1e-9)
			end
		end)

		it("merges a run of slots into one wide cell", function()
			local state = make(5, { 1, 2, 2, 2, 2, 3 }, { 1000, 10, 1000 })
			local cells = board.basket_cells(state)

			assert(#cells == 3, "got " .. #cells .. " cells")
			assert(math.abs(cells[2].width - state.geometry.step * 4) < 1e-9)
			assert(cells[2].first_slot == 2 and cells[2].last_slot == 5)
		end)

		it("centres a wide cell on the slots it covers", function()
			local state = make(5, { 1, 2, 2, 2, 2, 3 }, { 1000, 10, 1000 })
			local cells = board.basket_cells(state)

			local left = board.slot_position_of(state, 2)
			local right = board.slot_position_of(state, 5)
			assert(math.abs(cells[2].x - (left + right) / 2) < 1e-9,
				("cell at %s, slots span %s..%s"):format(cells[2].x, left, right))
		end)

		it("keeps non-adjacent slots of one basket as separate cells", function()
			local state = make(2, { 1, 2, 1 }, { 100, 5 })
			local cells = board.basket_cells(state)

			assert(#cells == 3, "a scattered basket must not draw as one cell")
			assert(cells[1].basket == 1 and cells[3].basket == 1)
		end)

		it("carries each basket's score", function()
			local state = make(5, { 1, 2, 2, 2, 2, 3 }, { 1000, 10, 1000 })
			local cells = board.basket_cells(state)

			assert(cells[1].score == 1000)
			assert(cells[2].score == 10)
			assert(cells[3].score == 1000)
		end)

		it("covers every slot exactly once", function()
			local state = make(9, { 1, 1, 2, 3, 4, 5, 6, 7, 8, 8 }, { 1, 2, 3, 4, 5, 6, 7, 8 })
			local covered = 0
			for _, cell in ipairs(board.basket_cells(state)) do
				covered = covered + (cell.last_slot - cell.first_slot + 1)
			end
			assert(covered == 10, "covered " .. covered .. " slots of 10")
		end)
	end)
end
