local custom_gruvbox = require "lualine.themes.gruvbox"
vim.o.background = "dark"
vim.cmd([[colorscheme gruvbox]])
require("lualine").setup {
    options = { theme = "gruvbox" }
}
