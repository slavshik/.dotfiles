local prettier = require("prettier")
local function has_prettier_config()
	return prettier.config_exists({ check_package_json = true })
end
-- !! prettierd is required to be installed globally via npm or brew
prettier.setup({
	bin = "prettierd",
	["null-ls"] = {
		condition = function()
			return has_prettier_config()
		end,
		-- runtime_condition = function(params)
		-- 	-- return false to skip running prettier
		-- 	return true
		-- end,
		timeout = 5000,
	},
})

local null_ls = require("null-ls")
local group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = false })
local event = "BufWritePre" -- or "BufWritePost"
local async = event == "BufWritePost"

null_ls.setup({
	on_attach = function(client, bufnr)
		if client.supports_method("textDocument/formatting") then
			-- format on save
			vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })
			vim.api.nvim_create_autocmd(event, {
				buffer = bufnr,
				group = group,
				callback = function()
					vim.lsp.buf.format({ bufnr = bufnr, async = async })
				end,
				desc = "[lsp] format on save",
			})
		end
	end,
	sources = { null_ls.builtins.formatting.stylua },
})
