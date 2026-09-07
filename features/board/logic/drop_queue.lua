--- Drops waiting to be launched.
-- Entries are already decided and already paid for; the queue only spaces them out in time.
local M = {}

---@param interval number seconds between launches
---@return table
function M.new(interval)
	return { interval = interval, waiting = {}, timer = 0, launched_any = false }
end

--- Adds decided drops to the back of the queue.
---@param state table
---@param entries table[] { drop, payout_id }
function M.push(state, entries)
	for _, entry in ipairs(entries) do
		state.waiting[#state.waiting + 1] = entry
	end
end

--- Advances the timer and returns what should launch now.
-- The first entry of an idle queue leaves immediately: waiting out an interval before anything
-- happens reads as a dead button.
---@param state table
---@param dt number
---@return table[]|nil entries
function M.update(state, dt)
	if #state.waiting == 0 then
		state.timer = 0
		state.launched_any = false
		return nil
	end

	local ready
	if not state.launched_any then
		state.launched_any = true
		ready = { table.remove(state.waiting, 1) }
	else
		ready = {}
	end

	state.timer = state.timer + dt
	while state.timer >= state.interval and #state.waiting > 0 do
		state.timer = state.timer - state.interval
		ready[#ready + 1] = table.remove(state.waiting, 1)
	end

	if #state.waiting == 0 then
		state.timer = 0
	end

	return #ready > 0 and ready or nil
end

--- Empties the queue and returns what was waiting. For a screen closing mid-queue: those wins
--- are already held and still have to be paid.
---@param state table
---@return table[] entries
function M.take_all(state)
	local waiting = state.waiting
	state.waiting = {}
	state.timer = 0
	state.launched_any = false
	return waiting
end

--- How many drops are still waiting.
---@param state table
---@return number
function M.count(state)
	return #state.waiting
end

return M
