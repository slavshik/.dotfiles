vim.api.nvim_create_autocmd(
    { "BufRead", "BufNew", "BufNewFile" },
    { pattern = "*.pcss", command = "set filetype=css" }
)
