require("lspsaga").setup({
	ui = {
		theme = "round",
		border = "rounded",
		winblend = 0,
	},
	symbol_in_winbar = {
		enable = true,
		color_mode = true,
		show_file = true,
		folder_level = 3,
		separator = " · ",
	},
	code_action = {
		extend_gitsigns = true,
	},
})

vim.keymap.set("n", ">", function()
	vim.cmd([[Lspsaga code_action]])
end)
vim.keymap.set("n", "<Leader>lo", function()
	vim.cmd([[Lspsaga outline]])
end, { desc = "LSP outline" })
vim.keymap.set("n", "<S-F6>", function()
	vim.cmd([[Lspsaga rename]])
	vim.cmd.wa()
end, { desc = "LSP rename" })
vim.keymap.set("n", "<C-n>", function()
	vim.cmd([[Lspsaga diagnostic_jump_next]])
end, { desc = "LSP next diagnostic" })
vim.keymap.set("n", "<C-p>", function()
	vim.cmd([[Lspsaga diagnostic_jump_prev]])
end, { desc = "LSP previous diagnostic" })
