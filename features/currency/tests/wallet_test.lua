---@diagnostic disable: undefined-global
local wallet = require("features.currency.logic.wallet")

local function config()
	return {
		balls = { start = 10, regen = { amount = 1, seconds = 10, cap = 10 } },
		coins = { start = 0 },
	}
end

return function()
	describe("Wallet", function()
		it("starts every currency at its configured balance", function()
			local state = wallet.new(config())
			assert(wallet.get(state, "balls") == 10)
			assert(wallet.get(state, "coins") == 0)
		end)

		it("refuses to spend more than the balance and leaves it untouched", function()
			local state = wallet.new(config())
			local spent = wallet.spend(state, "balls", 11)
			assert(spent == false)
			assert(wallet.get(state, "balls") == 10)
		end)

		it("spends exactly the balance", function()
			local state = wallet.new(config())
			local spent, balance = wallet.spend(state, "balls", 10)
			assert(spent == true)
			assert(balance == 0)
			assert(wallet.get(state, "balls") == 0)
		end)

		it("adds above any cap, since the cap belongs to refilling", function()
			local state = wallet.new(config())
			assert(wallet.add(state, "balls", 25) == 35)
		end)

		it("fails loudly on an unknown currency instead of reading zero", function()
			local state = wallet.new(config())
			local ok = pcall(wallet.get, state, "gems")
			assert(ok == false)
		end)

		it("snapshots balances without handing out its own table", function()
			local state = wallet.new(config())
			local snapshot = wallet.snapshot(state)
			snapshot.balls = 999
			assert(wallet.get(state, "balls") == 10)
		end)
	end)
end
