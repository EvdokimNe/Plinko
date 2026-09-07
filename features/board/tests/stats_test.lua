---@diagnostic disable: undefined-global
local stats = require("features.board.logic.stats")

local CONFIGURED = { 0.1, 0.2, 0.7 }

return function()
	describe("Stats", function()
		it("starts empty without dividing by zero", function()
			local state = stats.new(3)
			local rows = stats.report(state, CONFIGURED)
			for _, row in ipairs(rows) do
				assert(row.hits == 0)
				assert(row.share == 0)
				assert(row.points == 0)
			end
			local drops, points = stats.totals(state)
			assert(drops == 0 and points == 0)
		end)

		it("counts hits, points and shares together", function()
			local state = stats.new(3)
			stats.record(state, 2, 20)
			stats.record(state, 2, 20)
			stats.record(state, 3, 70)

			local rows = stats.report(state, CONFIGURED)
			assert(rows[2].hits == 2)
			assert(rows[2].points == 40)
			assert(math.abs(rows[2].share - 2 / 3) < 1e-9)
			assert(rows[3].share > 0.33 and rows[3].share < 0.34)
		end)

		it("keeps shares adding up to one", function()
			local state = stats.new(3)
			stats.record(state, 1, 10)
			stats.record(state, 3, 70)
			stats.record(state, 3, 70)

			local total = 0
			for _, row in ipairs(stats.report(state, CONFIGURED)) do
				total = total + row.share
			end
			assert(math.abs(total - 1) < 1e-9)
		end)

		it("keeps per-basket points summing to the total", function()
			local state = stats.new(3)
			stats.record(state, 1, 10)
			stats.record(state, 2, 20)
			stats.record(state, 3, 70)

			local sum = 0
			for _, row in ipairs(stats.report(state, CONFIGURED)) do
				sum = sum + row.points
			end
			local drops, points = stats.totals(state)
			assert(drops == 3)
			assert(sum == points)
			assert(points == 100)
		end)

		it("shows a basket that never received a ball", function()
			local state = stats.new(3)
			stats.record(state, 1, 10)
			local rows = stats.report(state, CONFIGURED)
			assert(#rows == 3)
			assert(rows[3].hits == 0 and rows[3].share == 0)
		end)

		it("passes the configured chance through untouched", function()
			local state = stats.new(3)
			for _ = 1, 20 do
				stats.record(state, 1, 10)
			end
			local rows = stats.report(state, CONFIGURED)
			assert(rows[1].configured == 0.1)
			assert(rows[1].share == 1)
		end)

		it("resets to empty and keeps counting afterwards", function()
			local state = stats.new(3)
			stats.record(state, 1, 10)
			stats.reset(state)

			local drops, points = stats.totals(state)
			assert(drops == 0 and points == 0)
			assert(stats.report(state, CONFIGURED)[1].hits == 0)

			stats.record(state, 2, 20)
			assert(select(1, stats.totals(state)) == 1)
		end)
	end)
end
