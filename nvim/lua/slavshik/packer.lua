local ensure_packer = function()
	local fn = vim.fn
	local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
	if fn.empty(fn.glob(install_path)) > 0 then
		fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
		vim.cmd([[packadd packer.nvim]])
		return true
	end
	return false
end

local _ = ensure_packer()

return require("packer").startup(function(use)
	use("wbthomason/packer.nvim")
	use("nvim-tree/nvim-tree.lua")
	use("ellisonleao/gruvbox.nvim")
	use("nvim-lualine/lualine.nvim")
	use({ "nvim-lua/telescope.nvim", requires = { { "nvim-lua/plenary.nvim" } } })
	use({ "nvim-telescope/telescope-file-browser.nvim" })
	use("nvim-treesitter/nvim-treesitter", { run = ":TSUpdate" })
	use("nvim-treesitter/playground")
	use("mbbill/undotree")
	-- git
	-- use("tpope/vim-fugitive")
	use("kdheepak/lazygit.nvim")
	use("ap/vim-css-color")
	-- file browser
	use({
		"lmburns/lf.nvim",
		requires = { "nvim-lua/plenary.nvim", "akinsho/toggleterm.nvim" },
	})
	use({ "lewis6991/gitsigns.nvim" })
	-- lsp
	use({
		"VonHeikemen/lsp-zero.nvim",
		requires = {
			-- LSP Support
			{ "neovim/nvim-lspconfig" },
			{ "williamboman/mason.nvim" },
			{ "williamboman/mason-lspconfig.nvim" },

			-- Autocompletion
			{ "hrsh7th/nvim-cmp" },
			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-path" },
			{ "saadparwaiz1/cmp_luasnip" },
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "hrsh7th/cmp-nvim-lua" },

			-- Snippets
			{ "L3MON4D3/LuaSnip" },
			{ "rafamadriz/friendly-snippets" },
		},
	})
	use({
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	})
	use({ "jose-elias-alvarez/null-ls.nvim" })
	use({
		"windwp/nvim-spectre",
		requires = {
			{ "nvim-lua/plenary.nvim" },
		},
	})
	-- pettier
	use({
		"MunifTanjim/prettier.nvim",
		requires = {
			{ "neovim/nvim-lspconfig" },
			{ "jose-elias-alvarez/null-ls.nvim" },
		},
	})
	-- eslint
	use("MunifTanjim/eslint.nvim")
	use("github/copilot.vim")
	use({
		"glepnir/lspsaga.nvim",
		branch = "main",
	})
	use({
		"folke/trouble.nvim",
		requires = "kyazdani42/nvim-web-devicons",
		config = function()
			require("trouble").setup({
				use_diagnostic_signs = false,
			})
		end,
	})
	use("onsails/lspkind-nvim") -- nice icons in drop-down
	use({
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	})
	-- Lua
	use({
		"folke/which-key.nvim",
		config = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
			require("which-key").setup({
				-- your configuration comes here
				-- or leave it empty to use the default settings
				-- refer to the configuration section below
			})
		end,
	})
	use("easymotion/vim-easymotion")
end)
