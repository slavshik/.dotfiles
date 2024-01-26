require("nvim-tree").setup({
	live_filter = {
		prefix = "[FILTER]: ",
		always_show_folders = false, -- Turn into false from true by default
	},
})

vim.keymap.set({ "n", "v" }, "<C-p>", ":NvimTreeFindFileToggle<CR>", { noremap = true, silent = true })
