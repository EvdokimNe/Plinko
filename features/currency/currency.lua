--- The service the rest of the game talks to about balances.
-- State lives here on purpose. The wallet outlives every screen: the menu shows the ball count,
-- the game screen spends balls, and refilling continues while neither is open. It is installed
-- at one known point rather than appearing by accident.
-- The logic behind it (`wallet`, `regeneration`) stays stateless and is tested directly.
local event = require("event.event")
local regeneration = require("features.currency.logic.regeneration")
local wallet = require("features.currency.logic.wallet")

local M = {}

local balances
local timers
local changed = {}
local persist

--- Builds the service. Called once, from the composition root.
---@param currency_config table the `currency` section of the config
function M.install(currency_config)
	assert(not balances, "currency service installed twice")
	balances = wallet.new(currency_config)
	timers = regeneration.new(currency_config)
	changed = {}
end

--- Drops the service. For tests, and for a full restart.
function M.uninstall()
	balances = nil
	timers = nil
	changed = {}
	persist = nil
end

local function notify(id, balance)
	local signal = changed[id]
	if signal then
		signal:trigger(balance)
	end
	if persist then
		persist()
	end
end

--- Advances refill timers. Driven by the service script's `update`, never by wall clock, so the
--- whole thing stays deterministic and testable.
---@param dt number
function M.update(dt)
	local credits = regeneration.update(timers, dt, balances.balances)
	if not credits then
		return
	end

	for id, amount in pairs(credits) do
		notify(id, wallet.add(balances, id, amount))
	end
end

--- Hands the balances to a storage layer. The callback receives a key and the table, and
--- returns the table to use — loaded values included. Called from the composition root, so this
--- module never depends on a save library.
---@param bind fun(key: string, value: table): table
function M.bind_storage(bind)
	balances.balances = bind("currency", balances.balances)
end

--- Called after every balance change, so nothing the player earned waits for a timer.
---@param callback fun()|nil
function M.set_persist(callback)
	persist = callback
end

--- Current balance of a currency.
---@param id string
---@return number
function M.balance(id)
	return wallet.get(balances, id)
end

--- Credits a currency. May take the balance above the refill cap — that is what the debug grant
--- does, and refilling simply idles until the balance comes back down.
---@param id string
---@param amount number
---@return number balance
function M.add(id, amount)
	local balance = wallet.add(balances, id, amount)
	notify(id, balance)
	return balance
end

--- Spends if the balance covers it, all or nothing.
---@param id string
---@param amount number
---@return boolean spent
function M.spend(id, amount)
	local spent, balance = wallet.spend(balances, id, amount)
	if spent then
		notify(id, balance)
	end
	return spent
end

--- Seconds until the next refill of a currency, or nil when it is full or never refills.
---@param id string
---@return number|nil
function M.time_to_next(id)
	return regeneration.time_to_next(timers, id, wallet.get(balances, id))
end

--- Subscribes to changes of one currency. The subscription is addressed to that currency, not
--- to a global bus, so a screen only wakes for the balance it displays.
---@param id string
---@param callback fun(balance: number)
function M.on_change(id, callback)
	changed[id] = changed[id] or event.create()
	changed[id]:subscribe(callback)
end

--- Drops a subscription. Screens call this in `final`, or the callback outlives its scene.
---@param id string
---@param callback fun(balance: number)
function M.off_change(id, callback)
	local signal = changed[id]
	if signal then
		signal:unsubscribe(callback)
	end
end

return M
