local function prettierd()
    return {
        exe = "prettierd",
        args = {vim.api.nvim_buf_get_name(0)},
        stdin = true
    }
end
require('formatter').setup({
    logging = true,
    filetype = {
        typescript = { prettierd },
        javascript = { prettierd },
        json = { prettierd },
    }
})
vim.api.nvim_create_autocmd('BufWritePost', { pattern = '*', command = 'FormatWrite' })
