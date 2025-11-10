require('mini.snippets').setup({})
require('mini.completion').setup({})

vim.lsp.enable({
    "ts_ls",
    "luals",
    "gopls"
})
