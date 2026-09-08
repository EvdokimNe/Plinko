--- The window prefab: a titled panel with a content anchor.
-- The scene is `/shared/ui/window.gui`, dropped into a screen as a template node; its children
-- arrive named `<prefix>/root`, `/header`, `/title` and `/content`.
-- A screen keeps its own content as one node and hands it to `attach`, because the editor cannot
-- parent a scene node into a template instance.
-- Deliberately tiny. A window that grows behaviour has become a screen.
local M = {}

--- Sets the window's title.
---@param prefix string the template instance id, e.g. "window"
---@param text string
function M.title(prefix, text)
	gui.set_text(gui.get_node(prefix .. "/title"), text)
end

--- Moves a node into the window, keeping it exactly where the editor put it.
---@param prefix string
---@param node userdata the screen's content root
function M.attach(prefix, node)
	gui.set_parent(node, gui.get_node(prefix .. "/content"), true)
end

return M
