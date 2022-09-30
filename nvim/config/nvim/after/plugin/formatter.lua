local util = require("formatter.util")
local function prettierd()
	return {
		exe = "prettierd",
		args = { vim.api.nvim_buf_get_name(0) },
		stdin = true,
	}
end
local lua_formatter = {
	-- "formatter.filetypes.lua" defines default configurations for the
	-- "lua" filetype
	require("formatter.filetypes.lua").stylua,

	-- You can also define your own configuration
	function()
		-- Supports conditional formatting
		if util.get_current_buffer_file_name() == "special.lua" then
			return nil
		end

		-- Full specification of configurations is down below and in Vim help
		-- files
		return {
			exe = "stylua",
			args = {
				"--search-parent-directories",
				"--stdin-filepath",
				util.escape_path(util.get_current_buffer_file_path()),
				"--",
				"-",
			},
			stdin = true,
		}
	end,
}
require("formatter").setup({
	logging = true,
	filetype = {
		typescript = { prettierd },
		javascript = { prettierd },
		json = { prettierd },
		lua = lua_formatter,
	},
})
vim.api.nvim_create_autocmd("BufWritePost", { pattern = "*", command = "FormatWrite" })
