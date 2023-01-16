require("lf").setup({
	escape_quit = true,
	border = "rounded",
	winblend = 0,
	escape_quit = true,
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
vim.keymap.set("n", "<Leader>l", ":Lf<CR>")
