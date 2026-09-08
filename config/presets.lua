--- Every board the player can choose. The menu builds a button per entry, so adding a board is
--- an entry here and nothing else.
-- Requires are literal because bob finds Lua dependencies by reading require strings.
return {
	{ id = "classic", label = "CLASSIC", board = require("config.presets.classic") },
	{ id = "left_heavy", label = "LEFT HEAVY", board = require("config.presets.left_heavy") },
	{ id = "wide", label = "WIDE BASKET", board = require("config.presets.wide") },
	{ id = "wide_basket_right", label = "WIDE RIGHT", board = require("config.presets.wide_basket_right") },
}
