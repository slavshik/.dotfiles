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

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ "n", "v" }, "<C-c>", [["+y]], { desc = "Copy to system clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]])
-- vim.keymap.set("n", "<C-Y>", [["+Y]])
--
vim.keymap.set("n", "Q", "<cmd>q!<cr>")
vim.keymap.set("x", "Q", "<nop>")
vim.keymap.set("n", "<C-s>", "<cmd>w<cr>")
vim.keymap.set("n", "<tab>", "<C-w>w")
-- Split window
vim.keymap.set("n", "ss", ":split<Return><C-w>w")
vim.keymap.set("n", "sv", ":vsplit<Return><C-w>w")
-- Exit vim
vim.keymap.set({ "n", "i", "v" }, "<C-b>W", vim.cmd.quit)
vim.keymap.set({ "n", "v" }, "`", "}")
vim.keymap.set({ "n", "v" }, "~", "{")
-- visual shifting (builtin-repeat)
vim.keymap.set({ "v" }, "<", "<gv")
vim.keymap.set({ "v" }, ">", ">gv")
-- easymotion
vim.keymap.set("n", "s", "<Plug>(easymotion-prefix)")
