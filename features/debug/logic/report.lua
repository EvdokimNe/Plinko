--- Turns board statistics into aligned lines of text.
-- Builds strings and nothing else, so the table is testable without a screen.
local M = {}

local COLUMNS = { 8, 7, 9, 9, 10 }

local function pad(value, width)
	local text = tostring(value)
	return text .. string.rep(" ", math.max(1, width - #text))
end

local function percent(share)
	return ("%.1f%%"):format(share * 100)
end

--- Header, one line per basket, a totals line, then a state line.
---@param stats_state table from `stats.new`
---@param rows table[] from `stats.report`
---@param state table { balls, in_flight, queued }
---@return string[]
function M.lines(stats_state, rows, state)
	local lines = {
		pad("BASKET", COLUMNS[1]) .. pad("HITS", COLUMNS[2]) .. pad("ACTUAL", COLUMNS[3])
			.. pad("CONFIG", COLUMNS[4]) .. pad("POINTS", COLUMNS[5]),
	}

	local hits, points, configured = 0, 0, 0
	for _, row in ipairs(rows) do
		hits = hits + row.hits
		points = points + row.points
		configured = configured + (row.configured or 0)

		lines[#lines + 1] = pad(row.basket, COLUMNS[1])
			.. pad(row.hits, COLUMNS[2])
			.. pad(percent(row.share), COLUMNS[3])
			.. pad(percent(row.configured or 0), COLUMNS[4])
			.. pad(row.points, COLUMNS[5])
	end

	lines[#lines + 1] = pad("TOTAL", COLUMNS[1])
		.. pad(hits, COLUMNS[2])
		.. pad(percent(hits > 0 and 1 or 0), COLUMNS[3])
		.. pad(percent(configured), COLUMNS[4])
		.. pad(points, COLUMNS[5])

	lines[#lines + 1] = ""
	lines[#lines + 1] = ("BALLS %d   IN FLIGHT %d   QUEUED %d")
		:format(state.balls, state.in_flight, state.queued)

	return lines
end

--- A `weights` line for the config that reproduces the pyramid's own distribution.
-- Printed rather than written: a web build cannot write into the project, and editing the
-- config behind the developer's back is worse than one line to copy.
---@param weights number[] paths reaching each basket
---@return string
function M.weights_line(weights)
	local parts = {}
	for index, weight in ipairs(weights) do
		parts[index] = tostring(weight)
	end
	return "weights = { " .. table.concat(parts, ", ") .. " },"
end

return M
