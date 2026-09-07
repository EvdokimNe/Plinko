--- A short board with a basket spanning several slots: five rows, six slots, three baskets.
-- The middle basket owns four of them, so it is wide and cheap; the edges are single slots and
-- rich, which is how a real Plinko cabinet is laid out.
return {
	rows = 5,
	basket_of_slot = { 1, 2, 2, 2, 2, 3 },
	weights = { 5, 90, 5 },
	scores = { 1000, 10, 1000 },
}
