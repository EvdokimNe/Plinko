--- Board geometry, payout table and the tuning of how a ball falls.
-- Numbers here are clamped on read. The allowed ranges live in config/init.lua (RANGES).
return {
	-- Rows of pins. A uniform pyramid: row N has N pins, so `rows` rows give `rows + 1` slots.
	-- Example: 9 rows -> 10 slots.
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
		-- 0 = every path to that basket is equally likely.
		-- Above 0 the ball spreads its turns evenly and looks calmer; below 0 it clumps
		-- them and swings wider. Never changes which basket it lands in.
		straightness = 0.0,
	},

	-- Everything visual. Pixels and scales only — nothing here changes odds or paths.
	view = {
		-- Size of the board area the pyramid is fitted into, in pixels.
		-- The art is 560x780; the pyramid and the baskets share this box.
		width = 560,
		height = 700,

		-- Vertical centre of the board area, measured from the centre of the screen.
		-- Negative moves it down, to leave room for the top panel.
		offset_y = -40,

		-- Scale applied to the pin sprite. The art is 44px against a 56px step at ten slots,
		-- so it starts at half size to leave a gap for the ball.
		pin_scale = 0.5,

		-- Scale of the glow underlay behind a pin, relative to the pin itself.
		pin_glow_scale = 1.4,

		-- Scale applied to the ball sprite. The art is 40px.
		ball_scale = 0.6,

		-- Height of a basket cell, in pixels.
		basket_height = 70,

		-- How many ball views to create up front. The pool grows past this if needed.
		ball_pool_size = 12,
	},

	fall = {
		-- Seconds for the whole drop, top row to basket.
		duration = 1.2,

		-- Time spent on a row, relative to the rows above it.
		-- Below 1 the ball speeds up as it falls, above 1 it slows down.
		row_pace = 0.9,

		-- How sharply the ball leaves a pin sideways. Range 1..4.
		-- 1 travels evenly between pins; higher darts away and coasts in.
		escape = 2.2,

		-- Upward hop after hitting a pin, in pixels. Range 0..60.
		-- 0 still accelerates downward, it just does not bounce up.
		hop = 12,
	},
}
