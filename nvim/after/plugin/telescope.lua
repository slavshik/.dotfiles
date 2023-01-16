local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>T", vim.cmd.Telescope)
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
-- remove duplicate
vim.keymap.set("n", "<leader>t", vim.cmd.Telescope)
vim.keymap.set("n", "<leader>o", builtin.find_files, {})
--------------------------------------------------------------
vim.keymap.set("n", "<leader>ds", builtin.lsp_document_symbols, {})
vim.keymap.set("n", "<leader>fg", builtin.git_files, {})
vim.keymap.set("n", "<leader>FF", builtin.live_grep, {})
vim.keymap.set("n", "<leader>ee", builtin.buffers, {})
