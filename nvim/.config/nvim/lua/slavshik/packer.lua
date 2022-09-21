-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  use 'github/copilot.vim'
  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-cmdline'

  use 'ThePrimeagen/harpoon'
  use 'fedepujol/move.nvim' 
 -- use 'hrsh7th/cmp-cmdline'
  use 'L3MON4D3/LuaSnip'
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  }
  use 'wbthomason/packer.nvim'
  use 'ellisonleao/gruvbox.nvim'
  use 'kyazdani42/nvim-web-devicons'
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.0',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  -- Formatters
  -- use 'sbdchd/neoformat'
  use 'mhartington/formatter.nvim'
  -- Git
  use 'kdheepak/lazygit.nvim'
  use 'BurntSushi/ripgrep'
  use 'nvim-telescope/telescope-fzy-native.nvim'
  use 'jakelinnzy/autocmd-lua'
  use("nvim-treesitter/nvim-treesitter", {
        run = ":TSUpdate"
    })
 -- Filefinder (lf.vim should be loaded before vim-floaterm to override vim-floaterm's lf wrapper)
 use "voitd/vim-floaterm"
 use 'ptzz/lf.vim'
  
end)
