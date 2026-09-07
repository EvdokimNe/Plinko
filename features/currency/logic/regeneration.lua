--- Currencies that refill over time.
-- Advanced with `dt` and the current balances, it returns what should be credited. It never
-- writes anywhere itself, so it can be tested without a wallet and driven from any clock.
local M = {}

--- Builds the timers. A currency whose config has no `regen` block is simply absent here and
--- therefore never refills.
---@param currency_config table
---@return table
function M.new(currency_config)
	local rules, timers = {}, {}
	for id, settings in pairs(currency_config) do
		if settings.regen then
			rules[id] = settings.regen
			timers[id] = 0
		end
	end
	return { rules = rules, timers = timers }
end

--- Advances the clocks and reports what to credit.
-- The timer only runs below the cap. At or above it the timer is held at zero rather than
-- accumulating, so a balance granted above the cap does not fall back into a burst of instant
-- refills — the countdown starts from the moment the balance drops back.
---@param state table
---@param dt number seconds
---@param balances table id -> current balance
---@return table|nil credits id -> amount, or nil when nothing is due
function M.update(state, dt, balances)
	local credits

	for id, rule in pairs(state.rules) do
		local balance = balances[id]
		if balance >= rule.cap then
			state.timers[id] = 0
		else
			local timer = state.timers[id] + dt
			local ticks = math.floor(timer / rule.seconds)

			if ticks > 0 then
				timer = timer - ticks * rule.seconds

				-- A long frame or a resumed tab can owe several ticks at once, but the cap
				-- still holds.
				local amount = math.min(ticks * rule.amount, rule.cap - balance)
				if amount > 0 then
					credits = credits or {}
					credits[id] = amount
				end

				-- Reaching the cap ends the cycle rather than leaving a part-filled timer that
				-- would credit the instant the player spends one unit.
				if balance + amount >= rule.cap then
					timer = 0
				end
			end

			state.timers[id] = timer
		end
	end

	return credits
end

--- Seconds until the next credit, or nil when the currency is full or never refills.
---@param state table
---@param id string
---@param balance number
---@return number|nil
function M.time_to_next(state, id, balance)
	local rule = state.rules[id]
	if not rule or balance >= rule.cap then
		return nil
	end
	return rule.seconds - state.timers[id]
end

return M
