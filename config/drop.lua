--- Dropping balls: the single drop and the queued multi-drop.
-- Numbers here are clamped on read. The allowed ranges live in config/init.lua (RANGES).
return {
	-- Seconds between balls released from the queue.
	queue_interval = 0.4,

	-- How many balls the multi-drop button queues at once.
	multi_count = 5,
}
