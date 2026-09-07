--- What every board shares: how it looks and how a ball falls.
-- Shape and odds live in config/presets/*.lua and are merged over this.
-- Numbers here are clamped on read. The allowed ranges live in config/init.lua (RANGES).
return {
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

	path = {
		-- How direct the ball looks on its way to the basket it already won.
		-- Range -1..1. 0 = every path to that basket is equally likely.
		-- Above 0 it spreads its turns and looks calmer; below 0 it clumps them and swings
		-- wider. Never changes which basket it lands in.
		straightness = 0.0,
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
