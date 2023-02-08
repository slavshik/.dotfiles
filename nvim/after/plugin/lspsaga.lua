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
})

vim.keymap.set("n", ">", function()
	vim.cmd([[Lspsaga code_action]])
end)
vim.keymap.set("n", "<Leader>lo", function()
	vim.cmd([[Lspsaga outline]])
end)
vim.keymap.set("n", "<S-F6>", function()
	vim.cmd([[Lspsaga rename]])
	vim.cmd.wa()
end)
vim.keymap.set("n", "<C-n>", function()
	vim.cmd([[Lspsaga diagnostic_jump_next]])
end)
vim.keymap.set("n", "<C-p>", function()
	vim.cmd([[Lspsaga diagnostic_jump_prev]])
end)
