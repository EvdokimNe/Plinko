--- Deterministic random source.
-- Not `math.random`: the engine runs LuaJIT on desktop and Lua 5.1 in the browser, so the
-- standard generator is not guaranteed to produce the same sequence on both, and a stored seed
-- has to replay a drop exactly.
-- Park-Miller: x = 48271 * x mod (2^31 - 1). The constants are chosen so the product stays
-- below 2^53 and survives in a double — the textbook 1103515245 multiplier silently loses
-- precision in Lua and stops being uniform.
local M = {}

local MODULUS = 2147483647
local MULTIPLIER = 48271

--- Creates a generator. Any seed works; 0 is shifted, since it is the one fixed point.
---@param seed number
---@return table
function M.new(seed)
	local state = math.floor(seed or 1) % MODULUS
	if state == 0 then
		state = 1
	end
	return { state = state }
end

--- Next value in (0, 1).
---@param rng table
---@return number
function M.next(rng)
	rng.state = (MULTIPLIER * rng.state) % MODULUS
	return rng.state / MODULUS
end

--- Next integer in [1, n].
---@param rng table
---@param n number
---@return number
function M.below(rng, n)
	return math.floor(M.next(rng) * n) + 1
end

return M
