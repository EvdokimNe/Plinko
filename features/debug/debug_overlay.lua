--- The debug readout, drawn with the engine's debug text.
-- `draw_debug_text` draws one frame and forgets, so the lines are posted every frame while
-- visible. Nothing here runs while hidden.
local report = require("features.debug.logic.report")

local M = {}

local RENDER = "@render:"
local DRAW = hash("draw_debug_text")

local LINE_HEIGHT = 18
local COLOR = vmath.vector4(1, 1, 1, 1)

--- Whether the readout can be shown at all. The engine draws `draw_debug_text` itself, and that
--- path is compiled out of a release build, so a release would toggle a panel that never appears.
--- A screen asks this before wiring anything to the readout.
---@return boolean
function M.is_available()
	return sys.get_engine_info().is_debug
end

--- @param origin table { x, y } top-left corner in screen pixels
---@return table
function M.new(origin)
	return { visible = false, origin = origin }
end

--- @param state table
---@return boolean visible
function M.toggle(state)
	state.visible = not state.visible
	return state.visible
end

---@param state table
---@return boolean
function M.is_visible(state)
	return state.visible
end

--- Posts the readout. Call every frame; does nothing while hidden.
---@param state table
---@param stats_state table
---@param rows table[] from `stats.report`
---@param status table { balls, in_flight, queued }
function M.draw(state, stats_state, rows, status)
	if not state.visible then
		return
	end

	local y = state.origin.y
	for _, line in ipairs(report.lines(stats_state, rows, status)) do
		if line ~= "" then
			msg.post(RENDER, DRAW, {
				text = line,
				position = vmath.vector3(state.origin.x, y, 0),
				color = COLOR,
			})
		end
		y = y - LINE_HEIGHT
	end
end

return M
