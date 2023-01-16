require("lspsaga").setup({
	ui = {
		theme = "round",
		border = "solid",
		winblend = 0,
	},
	symbol_in_winbar = {
		enable = true,
		color_mode = false,
		show_file = true,
		folder_level = 3,
		separator = " / ",
	},
})
vim.keymap.set("n", ">", "<cmd>Lspsaga code_action<cr>")
vim.keymap.set("n", "<Leader>r", "<cmd>Lspsaga rename<cr>")
