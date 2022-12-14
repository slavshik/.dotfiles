-- LSP
-- cmp_nvim_lsp.update_capabilities is deprecated, use cmp_nvim_lsp.default_capabilities instead. See :h deprecated
local null_ls = require("null-ls")
local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local lsp_formatting = function(bufnr)
	vim.lsp.buf.format({
		filter = function(client)
			-- apply whatever logic you want (in this example, we'll only use null-ls)
			return client.name == "null-ls"
		end,
		bufnr = bufnr,
	})
end
local on_attach = function(client, bufnr)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = 0 })
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = 0 })
	vim.keymap.set("n", "<Leader>D", vim.lsp.buf.type_definition, { buffer = 0 })
	vim.keymap.set("n", "<Leader>gi", vim.lsp.buf.implementation, { buffer = 0 })
	vim.keymap.set("n", ">", "<cmd>Lspsaga code_action<cr>", { buffer = 0 })
	vim.keymap.set("n", "gr", "<cmd>Trouble lsp_references<cr>", { buffer = 0 })
	-- vim.keymap.set("n", "<Leader>r", function()
	-- 	-- TODO: use Lspsaga
	-- 	vim.lsp.buf.rename()
	-- 	vim.cmd([[wa]])
	-- end)
	vim.keymap.set("n", "<Leader>r", "<cmd>Lspsaga rename<cr>", { buffer = bufnr })
	if client.supports_method("textDocument/formatting") then
		vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = augroup,
			buffer = bufnr,
			callback = function()
				lsp_formatting(bufnr)
			end,
		})
	end
end
null_ls.setup({
	on_attach = on_attach,
	sources = { require("null-ls").builtins.formatting.stylua },
})
local lsp_config = require("lspconfig")

lsp_config.tsserver.setup({
	on_attach = function(client, bufnr)
		on_attach(client, bufnr)
		vim.keymap.set("n", "Ø", "<CMD>OrganizeImports<CR>", { buffer = 0 })
	end,
	capabilities = capabilities,
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
-- require("luasnip.loaders.from_vscode").lazy_load()
local sumneko_root_path = os.getenv("HOME") .. "/.local/share/nvim/site/pack/packer/start/lua-language-server"
local sumneko_binary = "/opt/homebrew/bin/lua-language-server"
lsp_config.sumneko_lua.setup({
	cmd = { sumneko_binary, "-E", sumneko_root_path .. "/main.lua" },
	on_attach = function(client, buffer)
		vim.keymap.set("n", "<Leader>d", function()
			local exec = require("slavshik.exec2buff")
			exec({ "lua", vim.api.nvim_buf_get_name(0), 15 })
		end, { buffer = 0 })
		on_attach(client, buffer)
	end,
	capabilities = capabilities,
	settings = {
		Lua = {
			runtime = {
				-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
				version = "LuaJIT",
				-- Setup your lua path
				path = vim.split(package.path, ";"),
			},
			diagnostics = {
				globals = {
					"vim", -- Get the language server to recognize the `vim` global
					-- Defold
					"go",
					"hash",
					"factory",
					"collectionfactory",
					"msg",
					"vmath",
					"init",
					"on_message",
					"on_reload",
					"final",
				},
			},
			workspace = {
				-- Make the server aware of Neovim runtime files
				checkThirdParty = false,
				library = {
					[vim.fn.expand("$VIMRUNTIME/lua")] = true,
					[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
				},
			},
		},
	},
})
vim.opt.completeopt = { "menu", "menuone", "noselect" }
-- Set up nvim-cmp.
-- require("luasnip.loaders.from_vscode").lazy_load({ paths = { "~/.dotfiles/defold-vsc-snippets" } })
local cmp = require("cmp")
cmp.setup({
	snippet = {
		expand = function(args)
			-- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
			require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
			-- require("luasnip.loaders.from_vscode").lazy_load()
			-- require('snippy').expand_snippet(args.body) -- For `snippy` users.
			-- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
		end,
	},
	window = {
		-- completion = cmp.config.window.bordered(),
		-- documentation = cmp.config.window.bordered(),
	},
	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" }, -- For luasnip users.
		{ name = "nvim_lsp_signature_help" },
		-- { name = 'ultisnips' }, -- For ultisnips users.
		-- { name = 'snippy' }, -- For snippy users.
	}, {
		{ name = "buffer" },
	}),
})

-- autopairs
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline(),
	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		{ name = "cmdline" },
	}),
})
-- VSCore-lie pictograms
local lspkind = require("lspkind")
cmp.setup({
	formatting = {
		format = lspkind.cmp_format({
			mode = "symbol", -- show only symbol annotations
			maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)

			-- The function below will be called before any actual modifications from lspkind
			-- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
			before = function(entry, vim_item)
				return vim_item
			end,
		}),
	},
})
