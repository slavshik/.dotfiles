-- Seamless directional navigation + resize across nvim splits and tmux panes.
-- Pairs with the C-hjkl / M-hjkl bindings in tmux/tmux.conf (which read @pane-is-vim).
-- NOT lazy-loaded on keys: the plugin must load at startup so it sets @pane-is-vim,
-- otherwise tmux can't tell nvim is focused until the first keypress.
return {
	"mrjones2014/smart-splits.nvim",
	lazy = false,
	config = function()
		local ss = require("smart-splits")
		ss.setup({})
		-- Navigate (Tab still cycles windows inside nvim; C-j/C-k reserved for line-move)
		vim.keymap.set("n", "<C-h>", ss.move_cursor_left, { desc = "Go to left split/pane" })
		vim.keymap.set("n", "<C-l>", ss.move_cursor_right, { desc = "Go to right split/pane" })
		-- Resize (Alt+hjkl) — works on nvim splits and crosses into tmux panes
		vim.keymap.set("n", "<A-h>", ss.resize_left, { desc = "Resize split left" })
		vim.keymap.set("n", "<A-j>", ss.resize_down, { desc = "Resize split down" })
		vim.keymap.set("n", "<A-k>", ss.resize_up, { desc = "Resize split up" })
		vim.keymap.set("n", "<A-l>", ss.resize_right, { desc = "Resize split right" })
	end,
}
