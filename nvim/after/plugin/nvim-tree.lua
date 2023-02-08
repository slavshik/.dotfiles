require("nvim-tree").setup()

vim.keymap.set({ "n", "v" }, "<C-n>", ":NvimTreeFindFileToggle<CR>", { noremap = true, silent = true })
