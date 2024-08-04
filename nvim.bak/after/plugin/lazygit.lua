-- GIT! - remapped over to CMD+Shift+G in alacritty
vim.keymap.set("n", "<Leader>K", vim.cmd.LazyGit, { desc = "Toggle lazygit" })
-- LazyGit
vim.g.lazygit_floating_window_winblend = 0 -- transparency of floating window
vim.g.lazygit_floating_window_scaling_factor = 1.0 -- scaling factor for floating window
-- vim.g.lazygit_floating_window_corner_chars = ['╭', '╮', '╰', '╯'] -- customize lazygit popup window corner characters
-- vim.g.lazygit_floating_window_use_plenary = 1 -- use plenary.nvim to manage floating window if available
-- vim.g.lazygit_use_neovim_remote = 1 -- fallback to 0 if neovim-remote is not installed
-- vim.g.copilot_no_tab_map = true
