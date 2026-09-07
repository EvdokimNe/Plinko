---@diagnostic disable: undefined-global
local pool = require("features.board.logic.pool")

local function counter()
	local made = 0
	return function()
		made = made + 1
		return { id = made }
	end
end

return function()
	describe("Pool", function()
		it("creates the requested number up front", function()
			local state = pool.new(counter(), 5)
			assert(pool.made(state) == 5)
			assert(pool.in_use(state) == 0)
		end)

		it("hands out items and counts them", function()
			local state = pool.new(counter(), 3)
			local first = pool.take(state)
			local second = pool.take(state)
			assert(first ~= second)
			assert(pool.in_use(state) == 2)
			assert(pool.made(state) == 3, "should not create while the pool has spares")
		end)

		it("reuses a returned item instead of creating a new one", function()
			local state = pool.new(counter(), 1)
			local item = pool.take(state)
			pool.give(state, item)
			assert(pool.take(state) == item)
			assert(pool.made(state) == 1)
		end)

		it("grows when it runs dry rather than failing", function()
			local state = pool.new(counter(), 2)
			local taken = {}
			for index = 1, 5 do
				taken[index] = pool.take(state)
			end
			assert(pool.in_use(state) == 5)
			assert(pool.made(state) == 5)
			for index = 1, 5 do
				for other = index + 1, 5 do
					assert(taken[index] ~= taken[other], "handed the same item twice")
				end
			end
		end)

		it("refuses to take back something that is not out", function()
			local state = pool.new(counter(), 1)
			local ok = pcall(pool.give, state, { id = "stranger" })
			assert(ok == false)
		end)

		it("refuses to take back the same item twice", function()
			local state = pool.new(counter(), 1)
			local item = pool.take(state)
			pool.give(state, item)
			assert(pcall(pool.give, state, item) == false)
		end)

		it("returns everything at once", function()
			local state = pool.new(counter(), 4)
			for _ = 1, 4 do
				pool.take(state)
			end
			local returned = pool.give_all(state)
			assert(#returned == 4)
			assert(pool.in_use(state) == 0)
		end)
	end)
end
