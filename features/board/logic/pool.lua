--- A pool of reusable things.
-- Knows nothing about gui: it is handed a factory and hands back whatever that factory makes.
-- That keeps it testable without a scene, and lets the same pool serve any repeated view.
-- Balls are pooled because a queued multi-drop puts several in the air at once and the debug
-- grant can push far more; creating and destroying nodes per drop would churn the scene graph
-- for nothing.
local M = {}

--- Builds the pool and fills it.
---@param create fun(): any called for each item, up front and whenever the pool runs dry
---@param size number how many to create immediately
---@return table
function M.new(create, size)
	local state = { create = create, free = {}, used = {}, in_use = 0, made = 0 }
	for _ = 1, size do
		state.made = state.made + 1
		state.free[#state.free + 1] = create()
	end
	return state
end

--- Takes an item. Grows the pool rather than failing: a debug grant of fifty balls should not
--- break the screen.
---@param state table
---@return any item
function M.take(state)
	local item = table.remove(state.free)
	if not item then
		state.made = state.made + 1
		item = state.create()
	end

	state.used[item] = true
	state.in_use = state.in_use + 1
	return item
end

--- Returns an item. Giving back something that is not in use is a bug and fails loudly, since it
--- would otherwise hand the same item to two owners.
---@param state table
---@param item any
function M.give(state, item)
	assert(state.used[item], "returning an item that is not in use")
	state.used[item] = nil
	state.in_use = state.in_use - 1
	state.free[#state.free + 1] = item
end

--- Returns everything currently taken, in no particular order.
---@param state table
---@return any[] items
function M.give_all(state)
	local items = {}
	for item in pairs(state.used) do
		items[#items + 1] = item
	end
	for _, item in ipairs(items) do
		M.give(state, item)
	end
	return items
end

--- How many items are out.
---@param state table
---@return number
function M.in_use(state)
	return state.in_use
end

--- How many items were ever created. For spotting a pool that is always too small.
---@param state table
---@return number
function M.made(state)
	return state.made
end

return M
