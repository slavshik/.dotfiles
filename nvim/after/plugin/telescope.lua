local telescope = require("telescope")
local fb_actions = telescope.extensions.file_browser.actions

telescope.setup({
	defaults = {
		layout_config = {
			horizontal = {
				width = 0.9,
				height = 0.9,
				preview_width = 0.5,
			},
			vertical = {
				width = 0.9,
				height = 0.9,
				preview_height = 0.5,
			},
		},
	},
	pickers = {
		find_files = {
			theme = "ivy",
		},
		lsp_document_symbols = {
			theme = "dropdown",
		},
	},
	extensions = {
		file_browser = {
			layout_strategy = "center",
			layout_config = {
				prompt_position = "bottom",
				width = 0.9,
				height = 0.9,
			},
			-- disables netrw and use telescope-file-browser in its place
			-- hijack_netrw = true,
			mappings = {
				["i"] = {
					-- your custom insert mode mappings
				},
				["n"] = {
					["-"] = fb_actions.goto_parent_dir,
				},
			},
		},
	},
})
require("telescope").load_extension("file_browser")
vim.keymap.set("n", "<leader>O", function()
	require("telescope").extensions.file_browser.file_browser()
end, {})

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
