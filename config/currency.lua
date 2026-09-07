--- Currencies the player owns, and how each one regenerates.
-- A currency without a `regen` block simply never regenerates on its own.
-- Numbers here are clamped on read. The allowed ranges live in config/init.lua (CURRENCY_RANGES).
return {
	balls = {
		-- Balance on a first launch, before anything is saved.
		start = 10,

		regen = {
			-- How much is credited each tick.
			amount = 1,

			-- Seconds between ticks. Example: 10 = one ball every 10 seconds.
			seconds = 10,

			-- Regeneration stops at this balance.
			-- A manual grant may push the balance above it; regeneration then stays idle
			-- until the balance falls back below.
			cap = 10,
		},
	},

	-- Points. A currency like any other, so it gets a balance, a change event and a place in
	-- the save file for free. No `regen` block: points are earned, never refilled.
	score = {
		start = 0,
	},
}
