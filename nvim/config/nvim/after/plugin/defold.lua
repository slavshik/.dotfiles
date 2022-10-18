-- .script = "lua"
vim.api.nvim_create_autocmd(
	{ "BufRead", "BufNew", "BufNewFile" },
	{ pattern = "*.script,*.gui_script,*.render_script,*.editor_script", command = "set filetype=lua" }
)
