---@diagnostic disable: undefined-global
local drop_queue = require("features.board.logic.drop_queue")

local function entries(count, from)
	local list = {}
	for index = 1, count do
		list[index] = { drop = { basket = index }, payout_id = (from or 0) + index }
	end
	return list
end

return function()
	describe("Drop queue", function()
		it("launches the first drop immediately", function()
			local state = drop_queue.new(0.4)
			drop_queue.push(state, entries(1))

			local ready = drop_queue.update(state, 0)
			assert(ready and #ready == 1)
			assert(drop_queue.count(state) == 0)
		end)

		it("spaces the rest by the interval, in order", function()
			local state = drop_queue.new(0.4)
			drop_queue.push(state, entries(3))

			local first = drop_queue.update(state, 0)
			assert(#first == 1 and first[1].payout_id == 1)

			assert(drop_queue.update(state, 0.3) == nil, "released early")

			local second = drop_queue.update(state, 0.2)
			assert(second and #second == 1 and second[1].payout_id == 2)

			local third = drop_queue.update(state, 0.4)
			assert(third and #third == 1 and third[1].payout_id == 3)
		end)

		it("releases several after a long frame instead of losing them", function()
			local state = drop_queue.new(0.4)
			drop_queue.push(state, entries(5))
			drop_queue.update(state, 0)

			local ready = drop_queue.update(state, 2.0)
			assert(ready and #ready == 4, "expected 4, got " .. tostring(ready and #ready))
			assert(drop_queue.count(state) == 0)
		end)

		it("returns nothing while empty", function()
			local state = drop_queue.new(0.4)
			for _ = 1, 5 do
				assert(drop_queue.update(state, 1) == nil)
			end
		end)

		it("appends to a running queue without disturbing it", function()
			local state = drop_queue.new(0.4)
			drop_queue.push(state, entries(2))
			drop_queue.update(state, 0)

			drop_queue.push(state, entries(2, 100))
			assert(drop_queue.count(state) == 3)

			local ready = drop_queue.update(state, 0.4)
			assert(ready and ready[1].payout_id == 2, "order broken")
		end)

		it("starts fresh after emptying, so the next press launches at once", function()
			local state = drop_queue.new(0.4)
			drop_queue.push(state, entries(1))
			drop_queue.update(state, 0)
			drop_queue.update(state, 1)

			drop_queue.push(state, entries(1, 50))
			local ready = drop_queue.update(state, 0)
			assert(ready and ready[1].payout_id == 51)
		end)

		it("hands back everything waiting when the screen closes", function()
			local state = drop_queue.new(0.4)
			drop_queue.push(state, entries(4))
			drop_queue.update(state, 0)

			local left = drop_queue.take_all(state)
			assert(#left == 3)
			assert(drop_queue.count(state) == 0)
			assert(drop_queue.update(state, 5) == nil)
		end)
	end)
end
