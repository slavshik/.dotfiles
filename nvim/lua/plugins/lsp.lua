return {
	-- LSP
	{
		"neovim/nvim-lspconfig",
		cmd = { "LspInfo", "LspInstall", "LspStart" },
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "williamboman/mason.nvim" },
			{ "williamboman/mason-lspconfig.nvim" },
		},
		config = function()
			local lsp_zero = require("lsp-zero")

			-- lsp_attach is where you enable features that only work
			-- if there is a language server active in the file
			local lsp_attach = function(_, bufnr)
				local opts = { buffer = bufnr, remap = false }
				if _.name == "ts_ls" then
					-- !!! this is capital O here
					vim.keymap.set("n", "<C-ó>", "<CMD>OrganizeImports<CR>", opts)
				end
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
				-- vim.keymap.set("n", "<Leader>D", vim.lsp.buf.type_definition, opts)
				vim.keymap.set("n", "<Leader>gi", vim.lsp.buf.implementation, opts)
			end

			lsp_zero.extend_lspconfig({
				sign_text = true,
				lsp_attach = lsp_attach,
				capabilities = require("cmp_nvim_lsp").default_capabilities(),
			})
			lsp_zero.configure("lua_ls", {
				settings = { Lua = { diagnostics = { globals = { "vim" } } } },
			})
			lsp_zero.configure("ts_ls", {
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
							vim.lsp.buf.format({
								filter = function(client)
									return client.name == "null-ls"
								end,
								bufnr = bufnr,
							})
						end,
						description = "Organize Imports",
					},
				},
			})
			require("mason-lspconfig").setup({
				ensure_installed = {
					"ts_ls",
					"clangd",
					"gopls",
					"eslint",
					"lua_ls",
				},
				handlers = {
					-- this first function is the "default handler"
					-- it applies to every language server without a "custom handler"
					function(server_name)
						vim.lsp.config[server_name].setup({})
					end,
				},
			})
		end,
	},
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v4.x",
		lazy = true,
		config = false,
	},
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = true,
	},

	-- Autocompletion
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			{ "L3MON4D3/LuaSnip" },
		},
		config = function()
			local cmp = require("cmp")
			local cmp_mappings = cmp.mapping.preset.insert({
				["<Up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
				["<Down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
				["<Enter>"] = cmp.mapping.confirm({ select = true }),
			})

			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

			cmp.setup({
				sources = {
					{ name = "nvim_lsp" },
				},
				mapping = cmp_mappings,
				snippet = {
					expand = function(args)
						vim.snippet.expand(args.body)
					end,
				},
			})
		end,
	},
}
