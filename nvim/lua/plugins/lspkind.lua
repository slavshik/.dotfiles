return {
	"onsails/lspkind.nvim",
	config = function()
		-- drop down symbols for functions and variables
		local cmp = require("cmp")
		local lspkind = require("lspkind")
		cmp.setup({
			formatting = {
				format = lspkind.cmp_format({
					preset = "codicons",
					mode = "symbol",
					symbol_map = {
						Text = " ",
						Method = " ",
						Function = " ",
						Constructor = " ",
						Field = "ﰠ ",
						Variable = " ",
						Class = "ﴯ ",
						Interface = " ",
						Module = " ",
						Property = "ﰠ ",
						Unit = "塞 ",
						Value = " ",
						Enum = " ",
						Keyword = " ",
						Snippet = " ",
						Color = " ",
						File = " ",
						Reference = " ",
						Folder = " ",
						EnumMember = " ",
						Constant = " ",
						Struct = "פּ ",
						Event = " ",
						Operator = " ",
						TypeParameter = "",
					},
				}),
			},
		})
	end,
}
