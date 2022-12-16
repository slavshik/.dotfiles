require'nvim-treesitter.configs'.setup {
  ensure_installed = { "c", "typescript", "javascript", "lua", "rust" },
  sync_install = false,
  auto_install = true,

  highlight = {
    enable = true,
    disable = { "c", "rust" },
    additional_vim_regex_highlighting = false,
  },
}
