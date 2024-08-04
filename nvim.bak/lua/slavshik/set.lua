vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.config/.vim/undodir"
vim.opt.undofile = true
vim.opt.termguicolors = true
vim.g.autoread = true
---------------------------------
vim.opt.tabstop = 4
vim.opt.ic = true
vim.opt.softtabstop = 4
vim.opt.scrolloff = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.cursorline = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.smartindent = true

vim.opt.wrap = false
-- vim.opt.clipboard:append({ "unnamedplus" })

-- Give more space for displaying messages.
vim.opt.cmdheight = 1

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
-- delays and poor user experience.
vim.opt.updatetime = 50

vim.opt.signcolumn = "yes" -- git/errors/linters SHOW always to prevent blinking and shifting
--

vim.g.netrw_banner = 0
vim.g.mapleader = " "

vim.g.copilot_node_command = "~/.nvm/versions/node/$(cat ~/.nvm/alias/default)/bin/node"
