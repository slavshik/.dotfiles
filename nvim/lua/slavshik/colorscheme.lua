local custom_gruvbox = require("lualine.themes.gruvbox")
vim.o.background = "dark"
vim.cmd([[colorscheme gruvbox]])
vim.cmd([[hi normal guibg=None]])
require("lualine").setup({
	options = { theme = "gruvbox" },
})
