require("nvim-tree").setup()

vim.keymap.set({ "n", "v" }, "<C-p>", ":NvimTreeFindFileToggle<CR>", { noremap = true, silent = true })
