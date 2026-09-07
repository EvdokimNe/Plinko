---@diagnostic disable: undefined-global
local currency = require("features.currency.currency")

local function config()
	return {
		balls = { start = 10, regen = { amount = 1, seconds = 10, cap = 10 } },
		score = { start = 0 },
	}
end

return function()
	describe("Currency service", function()
		before(function()
			currency.uninstall()
			currency.install(config())
		end)

		after(function()
			currency.uninstall()
		end)

		it("refuses to install twice", function()
			assert(pcall(currency.install, config()) == false)
		end)

		it("spends and credits", function()
			assert(currency.spend("balls", 4) == true)
			assert(currency.balance("balls") == 6)
			currency.add("score", 250)
			assert(currency.balance("score") == 250)
		end)

		it("refuses a spend it cannot cover, leaving the balance alone", function()
			assert(currency.spend("balls", 99) == false)
			assert(currency.balance("balls") == 10)
		end)

		it("notifies subscribers of the currency that changed", function()
			local seen
			local function watch(balance)
				seen = balance
			end
			currency.on_change("balls", watch)

			currency.add("balls", 5)
			assert(seen == 15)

			currency.off_change("balls", watch)
			currency.add("balls", 1)
			assert(seen == 15, "callback fired after unsubscribing")
		end)

		it("refills over time, and stops at the cap", function()
			currency.spend("balls", 3)
			currency.update(9.9)
			assert(currency.balance("balls") == 7)
			currency.update(0.2)
			assert(currency.balance("balls") == 8)

			currency.update(1000)
			assert(currency.balance("balls") == 10, "refilled past the cap")
			assert(currency.time_to_next("balls") == nil)
		end)

		it("takes balances from storage and keeps using that table", function()
			local stored = { balls = 3, score = 999 }
			local bound_key
			currency.bind_storage(function(key, table_reference)
				bound_key = key
				for id, value in pairs(stored) do
					table_reference[id] = value
				end
				return table_reference
			end)

			assert(bound_key == "currency")
			assert(currency.balance("balls") == 3)
			assert(currency.balance("score") == 999)

			currency.add("score", 1)
			assert(currency.balance("score") == 1000)
		end)

		it("persists after every change, not on a timer", function()
			local writes = 0
			currency.set_persist(function()
				writes = writes + 1
			end)

			currency.add("score", 10)
			currency.spend("balls", 1)
			assert(writes == 2, "expected a write per change, got " .. writes)

			currency.spend("balls", 500) -- refused, nothing changed
			assert(writes == 2, "a refused spend should not write")
		end)

		it("persists a refill too", function()
			local writes = 0
			currency.spend("balls", 5)
			currency.set_persist(function()
				writes = writes + 1
			end)

			currency.update(10)
			assert(writes == 1, "a refill is a change the player would hate to lose")
		end)
	end)
end
