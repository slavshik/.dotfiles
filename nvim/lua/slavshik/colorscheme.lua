local custom_gruvbox = require("lualine.themes.gruvbox")
custom_gruvbox.insert.c.bg = "#ff0000"
vim.o.background = "dark"
vim.cmd([[colorscheme gruvbox]])
vim.cmd([[hi normal guibg=None]])
require("lualine").setup({
	options = { theme = custom_gruvbox },
})
