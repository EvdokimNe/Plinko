--- Board geometry, payout table and the tuning of how a ball falls.
-- Every number here is clamped on read by config/init.lua to the range noted beside it.
return {
	-- Rows of pins. A uniform pyramid: row N has N pins, so `rows` rows give `rows + 1` slots.
	-- Range 1..20. Example: 9 rows -> 10 slots.
	rows = 9,

	-- Which basket sits under each slot, left to right. Length must be `rows + 1`.
	-- 1:1 means one basket per slot. Repeating a number makes one basket span several slots,
	-- which is how the basket count is made configurable: baskets = max of this table.
	-- Example for 8 baskets over 10 slots: {1,1,2,3,4,5,6,7,8,8}
	basket_of_slot = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },

	-- Relative chance of each basket. Not percentages — they are normalised on read, so
	-- {1,1} and {50,50} behave identically. Must be >= 0 and not all zero.
	-- Indexed by basket, so length must equal the basket count.
	weights = { 1, 3, 8, 15, 23, 23, 15, 8, 3, 1 },

	-- Points awarded for landing in each basket. Indexed by basket.
	scores = { 500, 200, 100, 50, 10, 10, 50, 100, 200, 500 },

	path = {
		-- How direct the ball looks on its way to the basket it already won.
		-- Range -1..1. 0 = every path to that basket is equally likely.
		-- Above 0 the ball spreads its turns evenly and looks calmer; below 0 it clumps
		-- them and swings wider. Never changes which basket it lands in.
		straightness = 0.0,
	},

	fall = {
		-- Seconds for the whole drop, top row to basket. Range 0.2..10.
		duration = 1.2,

		-- Time spent on a row, relative to the rows above it. Range 0.2..3.
		-- Below 1 the ball speeds up as it falls, above 1 it slows down.
		row_pace = 0.9,

		-- Sideways kick when bouncing off a pin, in pixels. Range 0..60.
		bounce_x = 14,

		-- Upward hop after hitting a pin, in pixels. Range 0..60.
		bounce_y = 10,
	},
}
