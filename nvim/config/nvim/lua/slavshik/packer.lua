vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function(use)
	use("github/copilot.vim")
	use("neovim/nvim-lspconfig")
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-buffer")
	use("hrsh7th/cmp-path")
	use("hrsh7th/nvim-cmp")
	use("hrsh7th/cmp-cmdline")
	use("hrsh7th/cmp-nvim-lsp-signature-help")

	use("ThePrimeagen/harpoon")
	use("fedepujol/move.nvim")
	use("L3MON4D3/LuaSnip")
	use({
		"nvim-lualine/lualine.nvim",
		requires = { "kyazdani42/nvim-web-devicons", opt = true },
	})
	use("wbthomason/packer.nvim")
	use("ellisonleao/gruvbox.nvim")
	use("kyazdani42/nvim-web-devicons")
	use({
		"nvim-telescope/telescope.nvim",
		tag = "0.1.0",
		requires = { { "nvim-lua/plenary.nvim" } },
	})
	-- Formatters
	use("jose-elias-alvarez/null-ls.nvim")
	use("MunifTanjim/prettier.nvim")
	-- TODO: delete
	use("mhartington/formatter.nvim")
	-- Git
	use("kdheepak/lazygit.nvim")
	use("BurntSushi/ripgrep")
	use("nvim-telescope/telescope-fzy-native.nvim")
	use("nvim-treesitter/nvim-treesitter", { run = ":TSUpdate" })
	use("sumneko/lua-language-server")
	-- from craftzdog
	use("onsails/lspkind-nvim") -- nice icons in drop-down
	use({ "nvim-telescope/telescope-file-browser.nvim" }) -- FileBrowser
	-- nice git column signs
	use({
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
		end,
	})
	use({
		"glepnir/lspsaga.nvim",
		branch = "main",
		config = function()
			local saga = require("lspsaga")

			saga.init_lsp_saga({
				-- your configuration
			})
		end,
	})
	use({
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	})
	use({
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	})
end)
