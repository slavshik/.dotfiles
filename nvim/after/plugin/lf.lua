require("lf").setup({
	escape_quit = true,
	border = "rounded",
	-- highlights = { FloatBorder = { guifg = require("kimbox.palette").colors.magenta } },
	default_actions = {
		["<C-s>"] = "split",
		["<C-v>"] = "vsplit",
		["<C-t>"] = "tabedit",
		["<Enter>"] = "edit",
	},
	height = 0.60, -- height of the *floating* window
	width = 0.90, -- width of the *floating* window
})
-- TODO: move this to a keymap file
vim.keymap.set("n", "<Leader>br", ":Lf<CR>")
