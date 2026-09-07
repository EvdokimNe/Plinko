--- Currencies the player owns, and how each one regenerates.
-- A currency without a `regen` block simply never regenerates on its own.
return {
	balls = {
		-- Balance on a first launch, before anything is saved. Range 0..9999.
		start = 10,

		regen = {
			-- How much is credited each tick. Range 1..999.
			amount = 1,

			-- Seconds between ticks. Range 1..86400. Example: 10 = one ball every 10 seconds.
			seconds = 10,

			-- Regeneration stops at this balance. Range 0..9999.
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
