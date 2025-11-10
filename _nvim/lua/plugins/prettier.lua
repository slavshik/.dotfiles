return {
	"MunifTanjim/prettier.nvim",
	dependencies = {
		{ "neovim/nvim-lspconfig" },
		{ "jose-elias-alvarez/null-ls.nvim" },
	},
	config = function()
		local prettier = require("prettier")

		prettier.setup({
			["null-ls"] = {
				bin = "prettierd",
				condition = function()
					return prettier.config_exists({ check_package_json = true })
				end,
				timeout = 5000,
			},
		})
	end,
}
