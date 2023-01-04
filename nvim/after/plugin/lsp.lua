local lsp = require("lsp-zero")

lsp.preset("recommended")
lsp.set_preferences({
	set_lsp_keymaps = true,
})
lsp.ensure_installed({
	"tsserver",
	"eslint",
	"sumneko_lua",
})
-- Fix Undefined global `vim`
lsp.configure("sumneko_lua", {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
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
	local opts = { buffer = bufnr, remap = false }
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
	-- vim.keymap.set("n", "<Leader>D", vim.lsp.buf.type_definition, opts)
	vim.keymap.set("n", "<Leader>gi", vim.lsp.buf.implementation, opts)
end)
lsp.setup()
