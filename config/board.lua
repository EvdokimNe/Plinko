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

		-- Size of the flash under a pin at its peak, relative to the pin. The glow is invisible
		-- until a ball strikes, then grows to this and shrinks back to nothing.
		pin_glow_scale = 2.4,

		-- Seconds the flash takes to grow, and to shrink again. Short and uneven reads as a
		-- hit; make them equal and it reads as a pulse, longer and the board looks lit.
		glow_grow = 0.06,
		glow_fade = 0.14,

		-- Scale applied to the ball sprite. The art is 40px.
		ball_scale = 0.6,

		-- Height of a basket cell, in pixels.
		basket_height = 70,

		-- The basket that just took a ball flashes white and its number jumps, then both ease
		-- back over these seconds. One duration for the pair, so they finish together.
		basket_flash = 0.25,

		-- How far the number overshoots before it eases back, as a multiple of its own scale.
		-- Above about 1.5 the number leaves its cell on a narrow basket.
		basket_label_bump = 1.3,

		-- How many ball views to build at load. The pool makes more on demand and keeps them,
		-- so this only trades a little work at open against a little work on the first drops.
		ball_prewarm = 5,
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
