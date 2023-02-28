local lsp = require("lsp-zero")

lsp.preset("recommended")
lsp.set_preferences({
	set_lsp_keymaps = true,
})
lsp.ensure_installed({
	"tsserver",
	"gopls",
	"eslint",
	"lua_ls",
})
lsp.configure("lua_ls", {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
		},
	},
})
local lsp_formatting = function(bufnr)
	vim.lsp.buf.format({
		filter = function(client)
			-- apply whatever logic you want (in this example, we'll only use null-ls)
			return client.name == "null-ls"
		end,
		bufnr = bufnr,
	})
end
lsp.configure("tsserver", {
	commands = {
		OrganizeImports = {
			function()
				local params = {
					command = "_typescript.organizeImports",
					arguments = { vim.api.nvim_buf_get_name(0) },
					title = "",
				}
				local bufnr = vim.api.nvim_get_current_buf()
				vim.lsp.buf_request_sync(bufnr, "workspace/executeCommand", params, 1000)
				lsp_formatting(bufnr)
			end,
			description = "Organize Imports",
		},
	},
})
local cmp = require("cmp")
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_mappings = lsp.defaults.cmp_mappings({
	["<Up>"] = cmp.mapping.select_prev_item(cmp_select),
	["<Down>"] = cmp.mapping.select_next_item(cmp_select),
	["<Enter>"] = cmp.mapping.confirm({ select = true }),
})
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
-- Copilot
cmp_mappings["<Tab>"] = nil
cmp_mappings["<S-Tab>"] = nil
lsp.setup_nvim_cmp({ mapping = cmp_mappings })
lsp.on_attach(function(_, bufnr)
	if _.name == "tsserver" then
		-- !!! this is capital O here
		vim.keymap.set("n", "<C-ó>", "<CMD>OrganizeImports<CR>", { buffer = 0 })
	end
	local opts = { buffer = bufnr, remap = false }
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
	-- vim.keymap.set("n", "<Leader>D", vim.lsp.buf.type_definition, opts)
	vim.keymap.set("n", "<Leader>gi", vim.lsp.buf.implementation, opts)
end)
lsp.setup()
