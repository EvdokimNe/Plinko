--- The button prefab: a nine-sliced panel with a label inside.
-- The scene is `/shared/ui/button.gui`. A screen that needs a fixed number of buttons drops
-- template instances into its own scene; this module is for the other case — a count that comes
-- from data, where one hidden instance is cloned per item.
-- Slicing keeps the round art's corners while the middle stretches, so one circular sprite makes
-- buttons of any width.
local M = {}

--- Clones a hidden template instance and wires a Druid button to the copy.
---@param druid table the screen's druid instance
---@param options table { template, parent, text, x, y, width, height, callback }
---@return table button the Druid component
---@return userdata root
---@return userdata label
function M.spawn(druid, options)
	local source = gui.get_node(options.template .. "/root")
	local label_id = gui.get_id(gui.get_node(options.template .. "/label"))

	local cloned = gui.clone_tree(source)
	local root = cloned[gui.get_id(source)]
	local label = cloned[label_id]

	gui.set_parent(root, gui.get_node(options.parent))
	gui.set_enabled(root, true)
	gui.set_position(root, vmath.vector3(options.x or 0, options.y or 0, 0))

	if options.width and options.height then
		gui.set_size(root, vmath.vector3(options.width, options.height, 0))
	end

	gui.set_text(label, options.text)

	return druid:new_button(root, options.callback), root, label
end

return M
