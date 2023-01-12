local move_line_down = ":m '>+1<CR>gv=gv"
local move_line_up = ":m '<-2<CR>gv=gv"
vim.keymap.set("v", "<C-k>", move_line_up)
vim.keymap.set("v", "<C-j>", move_line_down)
vim.keymap.set("n", "<C-j>", "V" .. move_line_down .. "<esc>")
vim.keymap.set("n", "<C-k>", "V" .. move_line_up .. "<esc>")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set({ "n", "v" }, "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')
vim.keymap.set("n", "Q", vim.cmd.quit)
vim.keymap.set("n", "<tab>", "<C-w>w")
-- Split window
vim.keymap.set("n", "ss", ":split<Return><C-w>w")
vim.keymap.set("n", "sv", ":vsplit<Return><C-w>w")
