local function prettierd()
   return {
    exe = "prettierd",
    args = {vim.api.nvim_buf_get_name(0)},
    stdin = true
  }
end
require('formatter').setup({
  logging = false,
  filetype = {
    typescript = { prettierd },
    javascript = { prettierd },
    json = { prettierd },
  }
})
require('autocmd-lua').augroup {
  group = 'my_group',
  autocmds = {
    -- { 'BufWritePre', '*', '<cmd>Neoformat<CR>'}
    { event = 'BufWritePost', pattern = '*', cmd = function() vim.cmd[[FormatWrite]] end }
  }
}
