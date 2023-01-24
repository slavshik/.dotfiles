require("lspsaga").setup({
	ui = {
		theme = "round",
		border = "rounded",
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
vim.keymap.set("n", "<Leader>lo", "<cmd>Lspsaga outline<cr>")
vim.keymap.set("n", "<Leader>lr", "<cmd>Lspsaga rename<cr>")
