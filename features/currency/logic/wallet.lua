--- Balances of every currency the player owns.
-- Knows nothing about time: regeneration is a separate module. Knows nothing about events
-- either — notifying is the facade's job, so this stays a plain data structure that tests can
-- drive directly.
local M = {}

--- Builds the wallet from the currency section of the config.
---@param currency_config table id -> { start = number, regen = table|nil }
---@return table
function M.new(currency_config)
	local balances = {}
	for id, settings in pairs(currency_config) do
		balances[id] = settings.start
	end
	return { balances = balances }
end

--- Current balance. An unknown id is a wiring mistake and fails loudly rather than reading zero.
---@param state table
---@param id string
---@return number
function M.get(state, id)
	local balance = state.balances[id]
	assert(balance, "unknown currency: " .. tostring(id))
	return balance
end

--- Credits the balance. Used by regeneration and by the debug grant, which may exceed any cap.
---@param state table
---@param id string
---@param amount number
---@return number balance after the change
function M.add(state, id, amount)
	local balance = M.get(state, id) + amount
	state.balances[id] = balance
	return balance
end

--- Spends if the balance covers it. Refuses as a whole rather than going negative or partial.
---@param state table
---@param id string
---@param amount number
---@return boolean spent
---@return number balance
function M.spend(state, id, amount)
	local balance = M.get(state, id)
	if balance < amount then
		return false, balance
	end

	balance = balance - amount
	state.balances[id] = balance
	return true, balance
end

--- Every balance, for saving and for the debug readout.
---@param state table
---@return table id -> balance
function M.snapshot(state)
	local copy = {}
	for id, balance in pairs(state.balances) do
		copy[id] = balance
	end
	return copy
end

return M
