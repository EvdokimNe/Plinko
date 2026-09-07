---@diagnostic disable: undefined-global
local geometry = require("features.board.logic.geometry")

return function()
	describe("Geometry", function()
		it("counts pins as a triangular number", function()
			assert(geometry.pin_count(1) == 1)
			assert(geometry.pin_count(9) == 45)
		end)

		it("centres every row on the board", function()
			local geom = geometry.new(9, 560, 700)
			for row = 1, 9 do
				local left = geometry.pin(geom, row, 1)
				local right = geometry.pin(geom, row, row)
				assert(math.abs(left + right) < 1e-9,
					("row %d is not centred: %s..%s"):format(row, left, right))
			end
		end)

		it("spaces slots evenly and keeps them on the board", function()
			local width = 560
			local geom = geometry.new(9, width, 700)

			local previous
			for slot = 1, geom.slots do
				local x = geometry.slot(geom, slot)
				assert(math.abs(x) <= width / 2, ("slot %d at %s is off the board"):format(slot, x))
				if previous then
					assert(math.abs((x - previous) - geom.step) < 1e-9)
				end
				previous = x
			end
		end)

		it("drops each row below the one above", function()
			local geom = geometry.new(9, 560, 700)
			local previous
			for row = 1, 9 do
				local _, y = geometry.pin(geom, row, 1)
				if previous then
					assert(y < previous, "row " .. row .. " is not below the previous one")
				end
				previous = y
			end
			local _, slot_y = geometry.slot(geom, 1)
			assert(slot_y < previous, "slots are not below the last row")
		end)

		it("lands a finished path on the centre of its slot", function()
			local geom = geometry.new(9, 560, 700)
			for slot = 1, geom.slots do
				local ball_x = geometry.ball(geom, geom.rows, slot - 1)
				local slot_x = geometry.slot(geom, slot)
				assert(math.abs(ball_x - slot_x) < 1e-9,
					("slot %d: ball at %s, slot at %s"):format(slot, ball_x, slot_x))
			end
		end)

		it("releases the ball at the centre", function()
			local geom = geometry.new(9, 560, 700)
			local x = geometry.ball(geom, 0, 0)
			assert(x == 0)
		end)
	end)
end
