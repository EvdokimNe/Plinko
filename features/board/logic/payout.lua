--- Wins that are decided but not yet paid.
-- A drop is decided the instant the button is pressed — it has to be, or the configured
-- probabilities could not hold. But the player must not see the points before the ball arrives,
-- or the fall becomes decoration for a number that already moved.
-- So the win waits here: held on launch, released on landing. Everything visible — the balance,
-- the statistics, the save file — hangs off the release.
local M = {}

--- New, empty ledger.
---@return table
function M.new()
	return { held = {}, order = {}, next_id = 1 }
end

--- Holds a decided drop. Nothing is credited yet.
---@param state table
---@param drop table from `board.drop`
---@return number id to release it with
function M.hold(state, drop)
	local id = state.next_id
	state.next_id = id + 1
	state.held[id] = drop
	state.order[#state.order + 1] = id
	return id
end

local function forget(state, id)
	state.held[id] = nil
	for index, held_id in ipairs(state.order) do
		if held_id == id then
			table.remove(state.order, index)
			break
		end
	end
end

--- Releases one drop, because its ball landed. Returns nil for an id already released, so a
--- double landing cannot pay twice.
---@param state table
---@param id number
---@return table|nil drop
function M.release(state, id)
	local drop = state.held[id]
	if not drop then
		return nil
	end
	forget(state, id)
	return drop
end

--- Releases everything still in flight, in the order it was launched.
-- This is what makes leaving the screen mid-fall lose the animation and never the win.
---@param state table
---@return table[] drops
function M.release_all(state)
	local drops = {}
	for _, id in ipairs(state.order) do
		drops[#drops + 1] = state.held[id]
		state.held[id] = nil
	end
	state.order = {}
	return drops
end

--- How many balls are mid-air, their wins decided and unpaid.
---@param state table
---@return number
function M.pending(state)
	return #state.order
end

return M
