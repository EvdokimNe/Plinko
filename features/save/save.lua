--- Persistence, kept behind one file so the library stays replaceable.
-- Uses Insality's saver: it works in HTML5, where there is no ordinary file system, by
-- serialising into base64. See docs/DEPENDENCIES.md.
local saver = require("saver.saver")

local M = {}

local ready = false

--- Loads whatever was saved and starts the library's own autosave.
function M.install()
	saver.init()
	ready = true
end

--- Hands a table to the save file under `key`, and returns the table to use from now on —
--- previously saved values are already in it.
---@param key string
---@param table_reference table
---@return table
function M.bind(key, table_reference)
	assert(ready, "save.install() must run first")
	return saver.bind_save_state(key, table_reference)
end

--- Writes now. Called when something happened that the player would hate to lose.
function M.flush()
	if not ready then
		return
	end
	saver.save_game_state()
end

--- Wipes the save. For the debug panel and for tests.
function M.wipe()
	saver.delete_game_state()
end

return M
