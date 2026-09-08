--- The one place the rest of the game asks for tunable numbers.
-- Domain files are plain data; this module merges them, clamps every number to the range
-- documented beside it, and reports what it had to adjust. Clamping is never fatal: a bad
-- number becomes a sane one and says so, so a typo cannot silently change the game.
local M = {}

--- Ranges as {path, min, max}. A path names a number inside the merged table.
local RANGES = {
	{ "board.rows", 1, 20 },
	{ "board.path.straightness", -1, 1 },
	{ "board.fall.duration", 0.2, 10 },
	{ "board.fall.row_pace", 0.2, 3 },
	{ "board.fall.escape", 1, 4 },
	{ "board.fall.hop", 0, 60 },
	{ "board.view.ball_prewarm", 0, 100 },
	{ "board.view.glow_grow", 0.01, 1 },
	{ "board.view.glow_fade", 0.01, 1 },
	{ "board.view.basket_flash", 0.01, 2 },
	{ "board.view.basket_label_bump", 1, 3 },
	{ "drop.queue_interval", 0.05, 5 },
	{ "drop.multi_count", 2, 50 },
}

--- Ranges for the fields of one currency, relative to that currency's table.
local CURRENCY_RANGES = {
	{ "start", 0, 9999 },
	{ "regen.amount", 1, 999 },
	{ "regen.seconds", 1, 86400 },
	{ "regen.cap", 0, 9999 },
}

local function report(message)
	print("CONFIG: " .. message)
end

local function split(path)
	local parts = {}
	for part in path:gmatch("[^%.]+") do
		parts[#parts + 1] = part
	end
	return parts
end

local function resolve(root, parts)
	local holder = root
	for i = 1, #parts - 1 do
		holder = holder and holder[parts[i]]
	end
	return holder, parts[#parts]
end

local function clamp_at(root, path, min, max, label)
	local holder, key = resolve(root, split(path))
	if not holder then
		return
	end

	local value = holder[key]
	if value == nil then
		-- A range without a field means the config and the code disagree about what exists.
		report(("%s%s is missing; the config is out of step with the code"):format(label or "", path))
		return
	end
	if type(value) ~= "number" then
		return
	end

	local clamped = math.max(min, math.min(max, value))
	if clamped ~= value then
		holder[key] = clamped
		report(("%s%s was %s, clamped to %s (allowed %s..%s)")
			:format(label or "", path, value, clamped, min, max))
	end
end

--- Baskets are not stored anywhere: the largest basket index in the slot map is the count.
local function basket_count(basket_of_slot)
	local count = 0
	for _, basket in ipairs(basket_of_slot) do
		count = math.max(count, basket)
	end
	return count
end

--- A slot map of the wrong length cannot be clamped into anything meaningful, so it is
--- rebuilt as one basket per slot and reported loudly.
local function fix_slot_map(board)
	local slots = board.rows + 1
	if #board.basket_of_slot == slots then
		return
	end

	report(("board.basket_of_slot has %d entries but %d rows give %d slots; rebuilt as one basket per slot")
		:format(#board.basket_of_slot, board.rows, slots))

	local rebuilt = {}
	for slot = 1, slots do
		rebuilt[slot] = slot
	end
	board.basket_of_slot = rebuilt
end

--- Per-basket tables must cover every basket. A short one is padded with `fill`, a long one
--- keeps its extra entries out of reach and is reported.
local function fit_per_basket(board, field, baskets, fill)
	local list = board[field]
	if #list == baskets then
		return
	end

	report(("board.%s has %d entries for %d baskets; %s")
		:format(field, #list, baskets, #list < baskets and "padded" or "extra entries ignored"))

	for basket = #list + 1, baskets do
		list[basket] = fill
	end
	for basket = baskets + 1, #list do
		list[basket] = nil
	end
end

local function fix_weights(board)
	local total = 0
	for basket, weight in ipairs(board.weights) do
		if weight < 0 then
			report(("board.weights[%d] was %s, negative weights are meaningless, using 0"):format(basket, weight))
			board.weights[basket] = 0
		end
		total = total + board.weights[basket]
	end

	if total <= 0 then
		report("board.weights add up to zero, no basket could ever be drawn; using equal weights")
		for basket = 1, #board.weights do
			board.weights[basket] = 1
		end
	end
end

--- Contiguity matters because a basket is drawn as one cell: slots scattered across the board
--- cannot be one basket without the view lying about where balls land.
local function check_contiguous(basket_of_slot)
	local seen = {}
	local previous
	for slot, basket in ipairs(basket_of_slot) do
		if basket ~= previous then
			if seen[basket] then
				report(("basket %d owns slots that are not next to each other (slot %d); it will draw as separate cells")
					:format(basket, slot))
			end
			seen[basket] = true
			previous = basket
		end
	end
end

local function copy(source)
	local result = {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			result[key] = copy(value)
		else
			result[key] = value
		end
	end
	return result
end

local function find_preset(preset_id)
	for _, preset in ipairs(require("config.presets")) do
		if preset.id == preset_id then
			return preset
		end
	end
	error("unknown board preset: " .. tostring(preset_id))
end

local function load(preset_id)
	local board = copy(require("config.board"))
	for key, value in pairs(find_preset(preset_id).board) do
		board[key] = type(value) == "table" and copy(value) or value
	end

	local config = {
		preset = preset_id,
		board = board,
		currency = require("config.currency"),
		drop = require("config.drop"),
	}

	for _, range in ipairs(RANGES) do
		clamp_at(config, range[1], range[2], range[3])
	end

	for id, currency in pairs(config.currency) do
		for _, range in ipairs(CURRENCY_RANGES) do
			clamp_at(currency, range[1], range[2], range[3], "currency." .. id .. ".")
		end
	end

	config.board.rows = math.floor(config.board.rows)
	config.drop.multi_count = math.floor(config.drop.multi_count)
	config.board.view.ball_prewarm = math.floor(config.board.view.ball_prewarm)

	fix_slot_map(config.board)
	check_contiguous(config.board.basket_of_slot)
	local baskets = basket_count(config.board.basket_of_slot)
	fit_per_basket(config.board, "weights", baskets, 1)
	fit_per_basket(config.board, "scores", baskets, 0)
	fix_weights(config.board)
	config.board.baskets = baskets

	return config
end

local DEFAULT_PRESET = "classic"

local cached = {}

--- The merged, clamped configuration for one board preset.
-- The preset overrides shape and odds; everything visual comes from config/board.lua.
---@param preset_id string|nil defaults to the first board in the brief
---@return table
function M.get(preset_id)
	preset_id = preset_id or DEFAULT_PRESET
	cached[preset_id] = cached[preset_id] or load(preset_id)
	return cached[preset_id]
end

--- Every board the menu can offer.
---@return table[] { id, label }
function M.presets()
	return require("config.presets")
end

--- Drops the cache so the next `get` reloads. For tests and hot reload.
function M.reload()
	cached = {}
	for _, name in ipairs({ "config.board", "config.currency", "config.drop", "config.presets" }) do
		package.loaded[name] = nil
	end
	for _, preset in ipairs({ "classic", "left_heavy", "wide" }) do
		package.loaded["config.presets." .. preset] = nil
	end
end

return M
