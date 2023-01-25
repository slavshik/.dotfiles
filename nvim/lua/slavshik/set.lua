vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.config/.vim/undodir"
vim.opt.undofile = true
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
-- LazyGit
vim.g.lazygit_floating_window_winblend = 0 -- transparency of floating window
vim.g.lazygit_floating_window_scaling_factor = 1.0 -- scaling factor for floating window
-- vim.g.lazygit_floating_window_corner_chars = ['╭', '╮', '╰', '╯'] -- customize lazygit popup window corner characters
-- vim.g.lazygit_floating_window_use_plenary = 1 -- use plenary.nvim to manage floating window if available
-- vim.g.lazygit_use_neovim_remote = 1 -- fallback to 0 if neovim-remote is not installed
-- vim.g.copilot_no_tab_map = true
vim.g.netrw_banner = 0
vim.g.mapleader = " "
