---@diagnostic disable: undefined-global
local payout = require("features.board.logic.payout")

local function drop(basket, score)
	return { basket = basket, score = score }
end

return function()
	describe("Payout", function()
		it("holds a drop without paying it", function()
			local state = payout.new()
			payout.hold(state, drop(3, 100))
			assert(payout.pending(state) == 1)
		end)

		it("releases exactly the drop that was held", function()
			local state = payout.new()
			local first = payout.hold(state, drop(1, 500))
			local second = payout.hold(state, drop(7, 50))

			local released = payout.release(state, second)
			assert(released.basket == 7 and released.score == 50)

			released = payout.release(state, first)
			assert(released.basket == 1 and released.score == 500)
		end)

		it("pays a drop only once", function()
			local state = payout.new()
			local id = payout.hold(state, drop(2, 200))
			assert(payout.release(state, id) ~= nil)
			assert(payout.release(state, id) == nil)
			assert(payout.pending(state) == 0)
		end)

		it("ignores an unknown id", function()
			local state = payout.new()
			assert(payout.release(state, 42) == nil)
		end)

		it("releases out of order and keeps the rest", function()
			local state = payout.new()
			local a = payout.hold(state, drop(1, 10))
			local b = payout.hold(state, drop(2, 20))
			local c = payout.hold(state, drop(3, 30))

			assert(payout.release(state, b).basket == 2)
			assert(payout.pending(state) == 2)
			assert(payout.release(state, c).basket == 3)
			assert(payout.release(state, a).basket == 1)
			assert(payout.pending(state) == 0)
		end)

		it("pays everything in flight, in launch order", function()
			local state = payout.new()
			for basket = 1, 5 do
				payout.hold(state, drop(basket, basket * 10))
			end

			local drops = payout.release_all(state)
			assert(#drops == 5)
			for index = 1, 5 do
				assert(drops[index].basket == index, "out of order at " .. index)
			end
			assert(payout.pending(state) == 0)
		end)

		it("releases nothing when nothing is in flight", function()
			local state = payout.new()
			assert(#payout.release_all(state) == 0)
		end)

		it("keeps ids unique after a flush", function()
			local state = payout.new()
			local first = payout.hold(state, drop(1, 10))
			payout.release_all(state)
			local second = payout.hold(state, drop(2, 20))
			assert(second ~= first)
			assert(payout.release(state, first) == nil)
			assert(payout.release(state, second) ~= nil)
		end)
	end)
end
