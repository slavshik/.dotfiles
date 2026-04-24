return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    branch = "main",
    config = function()
        vim.filetype.add({ extension = { jsonl = 'json' } })

        local langs = {
            'c', 'lua', 'vim', 'vimdoc', 'query', 'javascript', 'html', 'typescript', 'tsx', 'json'
        }
        -- Install parsers
        require('nvim-treesitter').install(langs)

        -- Enable treesitter highlighting for all supported filetypes
        vim.api.nvim_create_autocmd('FileType', {
            pattern = langs,
            callback = function()
                vim.treesitter.start()
            end,
        })
    end,
}
