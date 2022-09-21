-- line numbers
vim.opt.nu = true
vim.opt.relativenumber = true
-- history
vim.g.noswapfile = true
vim.g.nobackup = true
-- vim.g.undodir = vim.fn.stdpath('.config') .. '/undodir'
---------------------------------
vim.opt.tabstop = 4
-- vim.opt.guicursor="n-v-c-sm:block,i-ci-ve:ver100,r-cr-o:hor20"
-- vim.opt.guicursor=""
vim.opt.ic = true
vim.opt.softtabstop = 4
vim.opt.scrolloff = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.cursorline = true
vim.hlsearch = false
vim.opt.incsearch = true
vim.opt.smartindent = true


vim.opt.wrap = false
vim.opt.clipboard = "unnamedplus"

vim.g.mapleader = " "

-- Give more space for displaying messages.
vim.opt.cmdheight = 1

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
-- delays and poor user experience.
vim.opt.updatetime = 50


vim.opt.signcolumn = "yes" -- git/errors/linters SHOW always to prevent blinking and shifting
