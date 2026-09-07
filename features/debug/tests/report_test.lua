---@diagnostic disable: undefined-global
local report = require("features.debug.logic.report")
local stats = require("features.board.logic.stats")

local CONFIGURED = { 0.25, 0.5, 0.25 }
local STATUS = { balls = 7, in_flight = 3, queued = 2 }

return function()
	describe("Debug report", function()
		it("renders every basket when nothing has landed", function()
			local state = stats.new(3)
			local lines = report.lines(state, stats.report(state, CONFIGURED), STATUS)

			-- header + 3 baskets + total + blank + status
			assert(#lines == 7, "got " .. #lines .. " lines")
			assert(lines[1]:find("BASKET"))
			assert(lines[2]:find("0.0%%"), "empty basket should read 0.0%")
		end)

		it("matches percentages to the counts", function()
			local state = stats.new(3)
			stats.record(state, 1, 10)
			stats.record(state, 2, 20)
			stats.record(state, 2, 20)
			stats.record(state, 2, 20)

			local lines = report.lines(state, stats.report(state, CONFIGURED), STATUS)
			assert(lines[2]:find("25.0%%"), "basket 1 should be 25%: " .. lines[2])
			assert(lines[3]:find("75.0%%"), "basket 2 should be 75%: " .. lines[3])
		end)

		it("sums the totals row", function()
			local state = stats.new(3)
			stats.record(state, 1, 10)
			stats.record(state, 3, 90)

			local lines = report.lines(state, stats.report(state, CONFIGURED), STATUS)
			local total = lines[#lines - 2]
			assert(total:find("TOTAL"))
			assert(total:find("2"), "two drops")
			assert(total:find("100"), "points summed: " .. total)
		end)

		it("passes the configured column through", function()
			local state = stats.new(3)
			local lines = report.lines(state, stats.report(state, CONFIGURED), STATUS)
			assert(lines[3]:find("50.0%%"), "basket 2 configured is 50%: " .. lines[3])
		end)

		it("shows balls, flight and queue", function()
			local state = stats.new(3)
			local lines = report.lines(state, stats.report(state, CONFIGURED), STATUS)
			local status_line = lines[#lines]
			assert(status_line:find("BALLS 7"))
			assert(status_line:find("IN FLIGHT 3"))
			assert(status_line:find("QUEUED 2"))
		end)

		it("keeps columns aligned as numbers grow", function()
			local state = stats.new(3)
			for _ = 1, 1234 do
				stats.record(state, 2, 9999)
			end

			local lines = report.lines(state, stats.report(state, CONFIGURED), STATUS)
			local header_hits = lines[1]:find("HITS")
			local row_hits = lines[3]:find("1234")
			assert(header_hits == row_hits, "columns drifted: " .. lines[1] .. " / " .. lines[3])
		end)

		it("formats a weights line ready to paste", function()
			assert(report.weights_line({ 1, 4, 6, 4, 1 }) == "weights = { 1, 4, 6, 4, 1 },")
		end)
	end)
end
