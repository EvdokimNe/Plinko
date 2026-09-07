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
	{ "board.fall.bounce_x", 0, 60 },
	{ "board.fall.bounce_y", 0, 60 },
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

local function load()
	local config = {
		board = require("config.board"),
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

	fix_slot_map(config.board)
	local baskets = basket_count(config.board.basket_of_slot)
	fit_per_basket(config.board, "weights", baskets, 1)
	fit_per_basket(config.board, "scores", baskets, 0)
	fix_weights(config.board)
	config.board.baskets = baskets

	return config
end

local cached

--- The merged, clamped configuration. Loaded once, then handed out as is.
---@return table
function M.get()
	cached = cached or load()
	return cached
end

--- Drops the cached configuration so the next `get` reloads it. For tests and hot reload.
function M.reload()
	cached = nil
	package.loaded["config.board"] = nil
	package.loaded["config.currency"] = nil
	package.loaded["config.drop"] = nil
end

return M
